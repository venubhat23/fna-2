class Lead < ApplicationRecord
  include PgSearch::Model

  validates :name, presence: true
  validates :contact_number, presence: true, uniqueness: { message: "Contact number already exists" }, format: { with: /\A[\+]?[0-9\s\-\(\)]+\z/, message: "Invalid phone number format" }
  validates :email, uniqueness: { message: "Email already exists" }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :current_stage, presence: true, inclusion: { in: ['lead_generated', 'consultation_scheduled', 'one_on_one', 'follow_up', 'follow_up_successful', 'follow_up_unsuccessful', 'not_interested', 'converted', 're_follow_up', 'policy_created', 'lead_closed'] }
  validates :lead_source, presence: true, inclusion: { in: ['online', 'offline', 'agent_referral', 'walk_in', 'tele_calling', 'campaign'] }
  validates :product_category, presence: true, inclusion: { in: ['insurance', 'investments', 'loans', 'taxation'] }
  validates :product_subcategory, presence: true
  validates :customer_type, presence: true, inclusion: { in: ['individual', 'corporate'] }
  validates :affiliate_id, presence: true, if: -> { !is_direct }
  validates :is_direct, inclusion: { in: [true, false] }

  # Individual Customer Required Fields
  validates :first_name, presence: true, format: { with: /\A[a-zA-Z\s]+\z/, message: "First name can only contain letters and spaces" }, if: :individual?
  validates :last_name, presence: true, format: { with: /\A[a-zA-Z\s]+\z/, message: "Last name can only contain letters and spaces" }, if: :individual?
  validates :middle_name, format: { with: /\A[a-zA-Z\s]*\z/, message: "Middle name can only contain letters and spaces" }, allow_blank: true, if: :individual?

  # Corporate Customer Required Fields
  validates :company_name, presence: true, if: :corporate?

  # Optional validations
  validates :gender, inclusion: { in: ['male', 'female', 'other'] }, allow_blank: true
  validates :marital_status, inclusion: { in: ['single', 'married', 'divorced', 'widowed'] }, allow_blank: true
  validates :pan_no, uniqueness: { message: "PAN number already exists" }, format: { with: /\A[A-Z]{5}\d{4}[A-Z]\z/ }, allow_blank: true
  validates :gst_no, format: { with: /\A\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z\d][A-Z\d]\z/ }, allow_blank: true
  validates :height, numericality: { greater_than: 3.5, less_than_or_equal_to: 8.0 }, allow_blank: true
  validates :weight, numericality: { greater_than: 10, less_than_or_equal_to: 300 }, allow_blank: true
  validates :annual_income, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :business_job, inclusion: { in: ['salaried', 'self_employed', 'business', 'professional', 'student', 'retired', 'unemployed', 'other'] }, allow_blank: true

  belongs_to :converted_customer, class_name: 'Customer', optional: true
  belongs_to :created_policy, class_name: 'Policy', optional: true
  belongs_to :affiliate, class_name: 'SubAgent', optional: true
  has_many :uploaded_documents, as: :documentable, class_name: 'Document', dependent: :destroy

  before_create :generate_lead_id
  before_update :update_stage_timestamp, if: :current_stage_changed?
  before_validation :set_name_from_customer_details
  before_validation :set_initial_stage

  enum :current_stage, {
    lead_generated: 'lead_generated',
    consultation_scheduled: 'consultation_scheduled',
    one_on_one: 'one_on_one',
    follow_up: 'follow_up',
    follow_up_successful: 'follow_up_successful',
    follow_up_unsuccessful: 'follow_up_unsuccessful',
    not_interested: 'not_interested',
    converted: 'converted',
    re_follow_up: 're_follow_up',
    policy_created: 'policy_created',
    lead_closed: 'lead_closed'
  }

  enum :lead_source, {
    online: 'online',
    offline: 'offline',
    agent_referral: 'agent_referral',
    walk_in: 'walk_in',
    tele_calling: 'tele_calling',
    campaign: 'campaign'
  }

  enum :product_category, {
    insurance: 'insurance',
    investments: 'investments',
    loans: 'loans',
    taxation: 'taxation'
  }

  enum :customer_type, {
    individual: 'individual',
    corporate: 'corporate'
  }

  # Define valid subcategories for each category
  PRODUCT_SUBCATEGORIES = {
    'insurance' => ['life', 'health', 'motor', 'general', 'travel', 'other'],
    'investments' => ['mutual_fund', 'gold', 'nps', 'bonds', 'other'],
    'loans' => ['personal', 'home', 'business', 'other'],
    'taxation' => ['itr', 'other']
  }.freeze

  scope :by_stage, ->(stage) { where(current_stage: stage) }
  scope :by_source, ->(source) { where(lead_source: source) }
  scope :by_product_category, ->(category) { where(product_category: category) }
  scope :by_product_subcategory, ->(subcategory) { where(product_subcategory: subcategory) }
  scope :recent, -> { order(created_date: :desc) }
  scope :pending_conversion, -> { where(current_stage: ['consultation_scheduled', 'one_on_one', 'follow_up', 're_follow_up']) }
  scope :converted_leads, -> { where(current_stage: 'converted') }
  scope :active_follow_up, -> { where(current_stage: ['follow_up', 're_follow_up']) }
  scope :direct_leads, -> { where(is_direct: true) }
  scope :referred_leads, -> { where(is_direct: false) }
  scope :by_affiliate, ->(affiliate_id) { where(affiliate_id: affiliate_id) }

  pg_search_scope :search_leads,
    against: [:name, :contact_number, :email, :referred_by, :product_category, :product_subcategory, :lead_id,
              :first_name, :middle_name, :last_name, :company_name],
    using: {
      tsearch: { prefix: true, any_word: true }
    }

  # Stage transition methods - Made more flexible to allow stage jumps
  def can_move_to_consultation?
    # Allow from lead_generated or any early stage
    lead_generated? || !cannot_change_stage?
  end

  def can_move_to_one_on_one?
    # Allow from consultation_scheduled or any non-final stage
    consultation_scheduled? || (!cannot_change_stage? && !in_follow_up_cycle?)
  end

  def can_move_to_follow_up?
    # Allow from one_on_one, consultation_scheduled, or any non-final stage
    one_on_one? || consultation_scheduled? || (!cannot_change_stage? && !in_follow_up_cycle?)
  end

  def can_mark_follow_up_successful?
    # Allow from follow_up, re_follow_up, or any stage that makes sense
    follow_up? || re_follow_up? || consultation_scheduled? || one_on_one? || (!cannot_change_stage?)
  end

  def can_mark_follow_up_unsuccessful?
    # Allow from follow_up, re_follow_up, or any stage that makes sense
    follow_up? || re_follow_up? || consultation_scheduled? || one_on_one? || (!cannot_change_stage?)
  end

  def can_mark_not_interested?
    # Allow from any stage except final stages
    !cannot_change_stage?
  end

  def can_re_follow_up?
    # Allow from follow_up_unsuccessful or any follow-up stage
    follow_up_unsuccessful? || follow_up? || (!cannot_change_stage?)
  end

  def can_convert_to_customer?
    # Allow conversion from any stage except already converted, policy created, or closed
    !['converted', 'policy_created', 'lead_closed'].include?(current_stage) && converted_customer_id.nil?
  end

  def can_create_policy?
    converted? && converted_customer_id.present?
  end

  def can_close_lead?
    not_interested? || (converted? && policy_created?) || (!cannot_change_stage?)
  end

  def cannot_change_stage?
    # Only prevent changes if lead is in truly final states
    policy_created? || lead_closed?
  end

  # Stage transition methods with validation
  def move_to_consultation_scheduled!
    return false unless can_move_to_consultation?
    update!(current_stage: 'consultation_scheduled')
  end

  def move_to_one_on_one!
    return false unless can_move_to_one_on_one?
    update!(current_stage: 'one_on_one')
  end

  def move_to_follow_up!
    return false unless can_move_to_follow_up?
    update!(current_stage: 'follow_up')
  end

  def mark_follow_up_successful!
    return false unless can_mark_follow_up_successful?
    update!(current_stage: 'follow_up_successful')
  end

  def mark_follow_up_unsuccessful!
    return false unless can_mark_follow_up_unsuccessful?
    update!(current_stage: 'follow_up_unsuccessful')
  end

  def mark_not_interested!
    return false unless can_mark_not_interested?
    update!(current_stage: 'not_interested')
  end

  def move_to_re_follow_up!
    return false unless can_re_follow_up?
    update!(current_stage: 're_follow_up')
  end

  def convert_to_customer!(customer_id)
    return false unless can_convert_to_customer?
    update!(current_stage: 'converted', converted_customer_id: customer_id)
  end

  def mark_policy_created!(policy_id = nil)
    return false unless can_create_policy?
    update!(current_stage: 'policy_created', policy_created_id: policy_id)
  end

  def close_lead!
    return false unless can_close_lead?
    update!(current_stage: 'lead_closed')
  end

  # Helper methods
  def converted?
    current_stage == 'converted'
  end

  def in_follow_up_cycle?
    ['follow_up', 'follow_up_successful', 'follow_up_unsuccessful', 're_follow_up'].include?(current_stage)
  end

  def can_settle_referral?
    current_stage == 'policy_created' && !transferred_amount && referral_amount > 0
  end

  def full_address
    [address, city, state].compact.join(', ')
  end

  def stage_badge_class
    case current_stage
    when 'lead_generated' then 'bg-secondary'
    when 'consultation_scheduled' then 'bg-info'
    when 'one_on_one' then 'bg-warning'
    when 'follow_up' then 'bg-primary'
    when 'follow_up_successful' then 'bg-success'
    when 'follow_up_unsuccessful' then 'bg-danger'
    when 'not_interested' then 'bg-dark'
    when 're_follow_up' then 'bg-warning'
    when 'converted' then 'bg-success'
    when 'policy_created' then 'bg-primary'
    when 'lead_closed' then 'bg-secondary'
    else 'bg-secondary'
    end
  end

  def source_badge_class
    case lead_source
    when 'online', 'campaign' then 'bg-info'
    when 'agent_referral' then 'bg-success'
    when 'walk_in' then 'bg-secondary'
    when 'tele_calling' then 'bg-purple'
    when 'offline' then 'bg-warning'
    else 'bg-light'
    end
  end

  def product_badge_class
    case product_category
    when 'insurance' then 'bg-primary'
    when 'investments' then 'bg-success'
    when 'loans' then 'bg-warning'
    when 'taxation' then 'bg-info'
    else 'bg-secondary'
    end
  end

  def next_stage_options
    # Define base next stage options
    base_options = case current_stage
    when 'lead_generated' then ['consultation_scheduled']
    when 'consultation_scheduled' then ['one_on_one']
    when 'one_on_one' then ['follow_up']
    when 'follow_up' then ['follow_up_successful', 'follow_up_unsuccessful', 'not_interested']
    when 're_follow_up' then ['follow_up_successful', 'follow_up_unsuccessful', 'not_interested']
    when 'follow_up_successful' then ['converted']
    when 'follow_up_unsuccessful' then ['re_follow_up']
    when 'converted' then ['policy_created']
    when 'not_interested' then ['lead_closed']
    when 'policy_created' then ['lead_closed']
    else []
    end

    # Add 'converted' option to all stages that can convert (except final stages)
    if can_convert_to_customer? && !base_options.include?('converted')
      base_options + ['converted']
    else
      base_options
    end
  end

  def stage_display_name
    case current_stage
    when 'lead_generated' then '🟢 Lead Generated'
    when 'consultation_scheduled' then '📅 Consultation Scheduled'
    when 'one_on_one' then '🤝 One-on-One Discussion'
    when 'follow_up' then '🔁 Follow-Up'
    when 'follow_up_successful' then '✅ Successful'
    when 'follow_up_unsuccessful' then '❌ Not Successful'
    when 'not_interested' then '🚫 Not Interested'
    when 're_follow_up' then '🔄 Re-Follow Up'
    when 'converted' then '👤 Convert to Customer'
    when 'policy_created' then '📄 Policy Created'
    when 'lead_closed' then '📁 Lead Closed'
    else current_stage.humanize
    end
  end

  def can_advance?
    next_stage_options.any?
  end

  def can_go_back?
    return false if locked_stage?

    # Define which stages can go back and to where
    case current_stage
    when 'consultation_scheduled'
      true # can go back to lead_generated
    when 'one_on_one'
      true # can go back to consultation_scheduled
    when 'follow_up'
      true # can go back to one_on_one
    when 'follow_up_successful', 'follow_up_unsuccessful', 'not_interested'
      true # can go back to follow_up
    when 're_follow_up'
      true # can go back to follow_up_unsuccessful
    else
      false # converted, policy_created, lead_closed cannot go back
    end
  end

  def next_stage
    # Get the first available next stage option
    next_stage_options.first
  end

  def previous_stage
    # Define reverse stage mapping for going back
    case current_stage
    when 'consultation_scheduled'
      'lead_generated'
    when 'one_on_one'
      'consultation_scheduled'
    when 'follow_up'
      'one_on_one'
    when 'follow_up_successful', 'follow_up_unsuccessful', 'not_interested'
      'follow_up'
    when 're_follow_up'
      'follow_up_unsuccessful'
    else
      nil
    end
  end

  def locked_stage?
    # Once policy is created or lead is closed, don't allow going back to prevent data inconsistency
    ['policy_created', 'lead_closed', 'converted'].include?(current_stage)
  end

  def stage_progress_percentage
    stages = ['lead_generated', 'consultation_scheduled', 'one_on_one', 'follow_up', 'converted', 'policy_created', 'lead_closed']
    current_index = stages.index(current_stage) || 0
    ((current_index + 1).to_f / stages.length * 100).round
  end

  def available_stages_for_transition
    # Return only valid next stage transitions, not all possible stages
    next_stage_options
  end

  def stage_description
    case current_stage
    when 'lead_generated' then 'Initial lead entry into system'
    when 'consultation_scheduled' then 'Initial consultation scheduled'
    when 'one_on_one' then 'Detailed discussion on premium and policy benefits'
    when 'follow_up' then 'Following up with customer for interest confirmation'
    when 'follow_up_successful' then 'Customer confirmed interest'
    when 'follow_up_unsuccessful' then 'Customer not interested at this time'
    when 'not_interested' then 'Customer explicitly not interested'
    when 're_follow_up' then 'Additional follow-up attempt'
    when 'converted' then 'Lead converted to customer'
    when 'policy_created' then 'Policy created and linked to customer'
    when 'lead_closed' then 'Lead process completed'
    else 'Unknown stage'
    end
  end

  def display_name
    if individual?
      "#{first_name} #{middle_name} #{last_name}".strip.squeeze(' ')
    elsif corporate?
      company_name
    else
      name
    end
  end

  def individual?
    customer_type == 'individual'
  end

  def corporate?
    customer_type == 'corporate'
  end

  def full_name
    if individual?
      "#{first_name} #{middle_name} #{last_name}".strip.squeeze(' ')
    else
      company_name || name
    end
  end

  def product_display_name
    "#{product_category&.humanize} - #{product_subcategory&.humanize}"
  end

  def insurance_interest
    product_subcategory&.humanize
  end

  def referral_type
    is_direct ? 'Direct' : 'Referred'
  end

  def affiliate_name
    affiliate&.display_name || 'N/A'
  end

  def created_date=(value)
    if value.is_a?(String) && value.match(/^\d{2}\/\d{2}\/\d{4}$/)
      parts = value.split('/')
      day, month, year = parts[0].to_i, parts[1].to_i, parts[2].to_i
      super(Date.new(year, month, day))
    else
      super(value)
    end
  end

  def formatted_created_date
    created_date&.strftime('%d/%m/%Y')
  end

  private

  def set_initial_stage
    self.current_stage = 'lead_generated' if current_stage.blank?
  end

  def generate_lead_id
    return if lead_id.present? # Don't regenerate if already set

    # Try to generate based on customer information if available
    if can_generate_custom_lead_id?
      self.lead_id = generate_custom_lead_id
    else
      # Fallback to legacy format for incomplete data
      generate_fallback_lead_id
    end

    # Ensure uniqueness
    ensure_lead_id_uniqueness
  end

  def can_generate_custom_lead_id?
    contact_number.present? && (
      (individual? && first_name.present?) ||
      (corporate? && company_name.present?)
    )
  end

  def generate_custom_lead_id
    # Extract first 5 characters of customer name
    customer_name_part = if individual? && first_name.present?
      first_name.to_s.strip.upcase[0, 5].ljust(5, 'X')
    elsif corporate? && company_name.present?
      company_name.to_s.strip.upcase[0, 5].ljust(5, 'X')
    else
      'CUSXX'
    end

    # Use first 5 characters of PAN number if available, otherwise use 5 random numbers
    pan_or_random_part = if pan_no.present?
      pan_no.to_s.strip.upcase[0, 5].ljust(5, 'X')
    else
      rand(10000..99999).to_s
    end

    "CUSLEAD-#{customer_name_part}-#{pan_or_random_part}"
  end

  def generate_fallback_lead_id
    # Use PAN number if present, otherwise use mobile number without +91 and spaces
    if pan_no.present?
      self.lead_id = pan_no
    elsif contact_number.present?
      # Clean mobile number: remove +91, spaces, and other formatting
      clean_mobile = contact_number.to_s.gsub(/[\s\-\(\)\+]/, '').gsub(/^91/, '')
      self.lead_id = clean_mobile
    else
      # Random ID if neither PAN nor mobile is available
      self.lead_id = "LEAD-#{Date.current.strftime('%Y%m%d')}-#{rand(1000..9999)}"
    end
  end

  def ensure_lead_id_uniqueness
    return unless lead_id.present?

    if Lead.where(lead_id: lead_id).where.not(id: id).exists?
      # If duplicate exists, append suffix
      original_id = lead_id
      counter = 1
      loop do
        self.lead_id = "#{original_id}-#{counter.to_s.rjust(2, '0')}"
        break unless Lead.where(lead_id: lead_id).where.not(id: id).exists?
        counter += 1
        # Safety check
        break if counter > 999
      end
    end
  end

  def update_stage_timestamp
    self.stage_updated_at = Time.current
  end

  def set_name_from_customer_details
    if name.blank?
      if individual? && first_name.present? && last_name.present?
        self.name = "#{first_name} #{middle_name} #{last_name}".strip.squeeze(' ')
      elsif corporate? && company_name.present?
        self.name = company_name
      else
        # Fallback for cases where customer type isn't set yet
        self.name = 'Lead' if name.blank?
      end
    end
  end
end
