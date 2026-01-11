class LifeInsurance < ApplicationRecord
  include PgSearch::Model
  include InsuranceCompanyConstants

  # Associations
  belongs_to :customer, counter_cache: :policies_count
  belongs_to :sub_agent, class_name: 'SubAgent', optional: true
  belongs_to :distributor, optional: true
  belongs_to :investor, optional: true
  belongs_to :agency_code, optional: true
  belongs_to :broker, optional: true
  has_many_attached :documents
  has_many_attached :policy_documents
  has_many :uploaded_documents, as: :documentable, class_name: 'Document', dependent: :destroy

  # New relationships for API structure
  has_many :life_insurance_nominees, dependent: :destroy
  has_one :life_insurance_bank_detail, dependent: :destroy
  has_many :life_insurance_documents, dependent: :destroy
  has_many :commission_payouts, -> { where(policy_type: 'life') }, foreign_key: 'policy_id', dependent: :destroy

  accepts_nested_attributes_for :life_insurance_nominees, allow_destroy: true
  accepts_nested_attributes_for :life_insurance_bank_detail, allow_destroy: true
  accepts_nested_attributes_for :life_insurance_documents, allow_destroy: true
  accepts_nested_attributes_for :uploaded_documents, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :policy_holder, presence: true
  validates :insurance_company_name, presence: true
  validates :policy_type, presence: true, inclusion: { in: ['New', 'Renewal'] }
  validates :policy_number, presence: true, uniqueness: { message: 'has already been taken. Each policy must have a unique policy number.' }
  validates :policy_booking_date, presence: true
  validates :policy_start_date, presence: true
  validates :policy_end_date, presence: true
  validates :payment_mode, presence: true
  validates :sum_insured, presence: true, numericality: { greater_than: 0 }
  validates :net_premium, presence: true, numericality: { greater_than: 0 }
  validates :first_year_gst_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_premium, presence: true, numericality: { greater_than: 0 }
  validates :policy_term, presence: true, numericality: { greater_than: 0 }
  validates :premium_payment_term, presence: true, numericality: { greater_than: 0 }
  validates :distributor_id, presence: true
  # investor_id removed - commission is collectively distributed

  # Custom validation
  validate :company_name_must_be_valid
  validate :end_date_after_start_date

  # Callbacks
  after_create :create_structured_payout

  # Enums for dropdowns
  POLICY_TYPES = ['New', 'Renewal'].freeze
  PAYMENT_MODES = ['Yearly', 'Half-Yearly', 'Quarterly', 'Monthly', 'Single'].freeze
  RELATIONSHIPS = ['Self', 'Spouse', 'Father', 'Mother', 'Son', 'Daughter', 'Brother', 'Sister', 'Other'].freeze
  ACCOUNT_TYPES = ['Savings', 'Current', 'Salary', 'Business'].freeze
  DOCUMENT_TYPES = ['PAN', 'Aadhaar', 'KYC', 'Payment Receipt', 'Medical Report', 'Other'].freeze

  # Scopes
  scope :active, -> { where('policy_end_date >= ?', Date.current) }
  scope :expired, -> { where('policy_end_date < ?', Date.current) }
  scope :expiring_soon, -> { where(policy_end_date: Date.current..30.days.from_now) }
  scope :new_policies, -> { where(policy_type: 'New') }
  scope :renewals, -> { where(policy_type: 'Renewal') }

  # Search
  pg_search_scope :search_life_policies,
    against: [:policy_number, :plan_name, :insurance_company_name, :insured_name],
    associated_against: {
      customer: [:first_name, :last_name, :company_name]
    },
    using: {
      tsearch: { prefix: true, any_word: true }
    }

  # Callbacks
  before_save :calculate_totals
  before_validation :set_policy_term_from_dates
  before_validation :normalize_numeric_fields
  after_save :set_notification_dates
  before_create :inherit_customer_lead_id
  after_create :create_commission_payouts
  after_create :create_lead_record

  # Instance methods
  def active?
    policy_end_date >= Date.current
  end

  def expired?
    policy_end_date < Date.current
  end

  def expiring_soon?
    policy_end_date.between?(Date.current, 30.days.from_now)
  end

  def days_until_expiry
    (policy_end_date - Date.current).to_i
  end

  def client_name
    customer.display_name
  end

  def affiliate_name
    sub_agent ? sub_agent.display_name : 'Self'
  end

  def total_rider_amount
    [
      term_rider_amount,
      critical_illness_rider_amount,
      accident_rider_amount,
      pwb_rider_amount,
      other_rider_amount
    ].compact.sum
  end

  def status
    return 'expired' if expired?
    return 'expiring_soon' if expiring_soon?
    'active'
  end

  def policy_holder_options
    options = [['Self', 'Self']]
    if customer&.family_members&.any?
      customer.family_members.each do |member|
        options << [member.full_name, member.id.to_s]
      end
    end
    options
  end

  def notifications_due_today
    return [] unless notification_dates.present?

    notification_list = JSON.parse(notification_dates)
    today = Date.current.to_s

    notification_list.select { |notification| notification['date'] == today }
  end

  # Dhanvantari Farm vs Non-Dhanvantari Farm classification
  def dhanvantri_policy?
    # Dhanvantari Farm: Admin Added policies (is_admin_added: true AND others false)
    is_admin_added? && !is_customer_added? && !is_agent_added?
  end

  def non_dhanvantri_policy?
    # Non-Dhanvantari Farm: Customer Added OR Agent Added policies
    (is_customer_added? && !is_admin_added? && !is_agent_added?) ||
    (is_agent_added? && !is_customer_added? && !is_admin_added?)
  end

  def policy_classification
    if dhanvantri_policy?
      'Dhanvantari Farm'
    elsif non_dhanvantri_policy?
      'Non-Dhanvantari Farm'
    else
      'Unknown'
    end
  end

  def policy_classification_badge_class
    case policy_classification
    when 'Dhanvantari Farm'
      'bg-success text-white'  # Green for Dhanvantari Farm
    when 'Non-Dhanvantari Farm'
      'bg-warning text-dark'   # Orange/Yellow for Non-Dhanvantari Farm
    else
      'bg-secondary text-white' # Gray for Unknown
    end
  end

  def self.all_notifications_due_today
    notifications = []

    all.each do |insurance|
      insurance.notifications_due_today.each do |notification|
        notifications << {
          id: "#{insurance.id}_#{notification['type']}",
          type: notification['type'],
          title: notification['title'],
          message: notification['message'],
          date: notification['date'],
          insurance_id: insurance.id,
          insurance_type: 'life'
        }
      end
    end

    notifications
  end

  private

  def calculate_totals
    if net_premium.present?
      # Calculate GST amounts
      first_year_gst = net_premium * (first_year_gst_percentage.to_f / 100.0)
      second_year_gst = net_premium * (second_year_gst_percentage.to_f / 100.0)
      third_year_gst = net_premium * (third_year_gst_percentage.to_f / 100.0)

      # Total premium calculation (for first year)
      self.total_premium = net_premium + first_year_gst

      # Commission calculations
      if main_agent_commission_percentage.present?
        self.commission_amount = net_premium * (main_agent_commission_percentage.to_f / 100.0)
      end

      if commission_amount.present? && tds_percentage.present?
        self.tds_amount = commission_amount * (tds_percentage.to_f / 100.0)
        self.after_tds_value = commission_amount - tds_amount
      end

      # Calculate new commission structure
      calculate_commission_structure
    end
  end

  def calculate_commission_structure
    return unless net_premium.present?

    # Set default company expenses percentage if not already set
    self.company_expenses_percentage ||= SystemSetting.company_expenses_percentage

    # Main income calculation (10% default)
    self.main_income_percentage ||= 10.0
    self.main_income_amount = net_premium * (main_income_percentage / 100.0)

    # Sub-agent commission (now Affiliate)
    self.sub_agent_commission_percentage ||= 2.0
    self.sub_agent_commission_amount = net_premium * (sub_agent_commission_percentage / 100.0)
    calculate_tds_for_sub_agent

    # Ambassador commission
    self.ambassador_commission_percentage ||= 2.0
    self.ambassador_commission_amount = net_premium * (ambassador_commission_percentage / 100.0)
    calculate_tds_for_ambassador

    # Distributor commission
    self.distributor_commission_percentage ||= 1.0
    self.distributor_commission_amount = net_premium * (distributor_commission_percentage / 100.0)
    calculate_tds_for_distributor

    # Investor commission
    self.investor_commission_percentage ||= 2.0
    self.investor_commission_amount = net_premium * (investor_commission_percentage / 100.0)
    calculate_tds_for_investor

    # Total distribution percentage
    self.total_distribution_percentage =
      sub_agent_commission_percentage +
      ambassador_commission_percentage +
      distributor_commission_percentage +
      investor_commission_percentage

    # Profit calculation
    remaining_percentage = main_income_percentage - total_distribution_percentage
    self.profit_percentage = remaining_percentage - company_expenses_percentage
    self.profit_amount = net_premium * (profit_percentage / 100.0)
  end

  def calculate_tds_for_sub_agent
    if sub_agent_commission_amount.present? && sub_agent_tds_percentage.present?
      self.sub_agent_tds_amount = sub_agent_commission_amount * (sub_agent_tds_percentage / 100.0)
      self.sub_agent_after_tds_value = sub_agent_commission_amount - sub_agent_tds_amount
    else
      self.sub_agent_after_tds_value = sub_agent_commission_amount
    end
  end

  def calculate_tds_for_ambassador
    if ambassador_commission_amount.present? && ambassador_tds_percentage.present?
      self.ambassador_tds_amount = ambassador_commission_amount * (ambassador_tds_percentage / 100.0)
      self.ambassador_after_tds_value = ambassador_commission_amount - ambassador_tds_amount
    else
      self.ambassador_after_tds_value = ambassador_commission_amount
    end
  end

  def calculate_tds_for_distributor
    if distributor_commission_amount.present? && distributor_tds_percentage.present?
      self.distributor_tds_amount = distributor_commission_amount * (distributor_tds_percentage / 100.0)
      self.distributor_after_tds_value = distributor_commission_amount - distributor_tds_amount
    else
      self.distributor_after_tds_value = distributor_commission_amount
    end
  end

  def calculate_tds_for_investor
    if investor_commission_amount.present? && investor_tds_percentage.present?
      self.investor_tds_amount = investor_commission_amount * (investor_tds_percentage / 100.0)
      self.investor_after_tds_value = investor_commission_amount - investor_tds_amount
    else
      self.investor_after_tds_value = investor_commission_amount
    end
  end

  def set_policy_term_from_dates
    # Only auto-calculate policy term if it's completely blank/nil
    # Don't override if user has manually selected a value
    if policy_start_date.present? && policy_end_date.present? && policy_term.nil?
      years = (policy_end_date - policy_start_date) / 365.25
      self.policy_term = years.round
    end
  end

  def company_name_must_be_valid
    return if insurance_company_name.blank?
    # Skip validation for customer-added policies (they can input any company name)
    return if is_customer_added?

    unless self.class.insurance_company_names.include?(insurance_company_name)
      errors.add(:insurance_company_name, "must be a valid insurance company")
    end
  end

  def end_date_after_start_date
    return unless policy_start_date && policy_end_date

    if policy_end_date <= policy_start_date
      errors.add(:policy_end_date, "must be after policy start date")
    end
  end

  def set_notification_dates
    return unless policy_end_date.present? && (saved_change_to_policy_end_date? || notification_dates.blank?)

    notification_schedule = []

    # 1 month before expiry
    one_month_before = policy_end_date - 30.days
    notification_schedule << {
      type: 'renewal',
      title: 'Life Policy Renewal Reminder - 1 Month',
      message: "Your life policy (#{policy_number}) is due for renewal on #{policy_end_date.strftime('%d %b %Y')}. Please renew to continue your coverage.",
      date: one_month_before.to_s
    }

    # 15 days before expiry
    fifteen_days_before = policy_end_date - 15.days
    notification_schedule << {
      type: 'renewal',
      title: 'Life Policy Renewal Reminder - 15 Days',
      message: "Your life policy (#{policy_number}) expires in 15 days on #{policy_end_date.strftime('%d %b %Y')}. Please renew to avoid coverage gap.",
      date: fifteen_days_before.to_s
    }

    # 7 days before expiry
    seven_days_before = policy_end_date - 7.days
    notification_schedule << {
      type: 'renewal',
      title: 'Life Policy Renewal Reminder - 1 Week',
      message: "Your life policy (#{policy_number}) expires in 1 week on #{policy_end_date.strftime('%d %b %Y')}. Immediate action required.",
      date: seven_days_before.to_s
    }

    # 1 day before expiry
    one_day_before = policy_end_date - 1.day
    notification_schedule << {
      type: 'renewal',
      title: 'Life Policy Renewal Reminder - Final Notice',
      message: "Your life policy (#{policy_number}) expires tomorrow on #{policy_end_date.strftime('%d %b %Y')}. Renew now to avoid coverage gap.",
      date: one_day_before.to_s
    }

    # Only include future dates
    future_notifications = notification_schedule.select { |n| Date.parse(n[:date]) >= Date.current }

    update_column(:notification_dates, future_notifications.to_json) if future_notifications.any?
  end

  def create_commission_payouts
    # Commission payouts are now handled by StructuredPayoutService in create_structured_payout
    # This method is kept for backward compatibility but does nothing to avoid duplicates
    Rails.logger.info "Commission payouts handled by StructuredPayoutService for life insurance #{id}"
  end

  def create_lead_record
    return if lead_id.present? # Skip if lead already exists
    return if is_customer_added? # Skip auto-creation for customer-added policies

    LeadGeneratorService.create_lead_for_insurance(self)
  rescue StandardError => e
    Rails.logger.error "Failed to create lead for life insurance #{id}: #{e.message}"
  end

  # Inherit lead_id from customer if not already set
  def inherit_customer_lead_id
    return if lead_id.present? || customer.nil? || customer.lead_id.blank?

    # Check if customer's lead_id is already used by another life insurance policy
    if LifeInsurance.exists?(lead_id: customer.lead_id)
      # Generate a unique lead_id for this policy
      base_lead_id = customer.lead_id
      counter = 1

      loop do
        new_lead_id = "#{base_lead_id}-#{counter}"
        unless LifeInsurance.exists?(lead_id: new_lead_id)
          self.lead_id = new_lead_id
          break
        end
        counter += 1
        # Safety check to prevent infinite loop
        break if counter > 1000
      end
    else
      self.lead_id = customer.lead_id
    end
  end

  def create_structured_payout
    return unless net_premium.present? && net_premium > 0
    return if is_customer_added? # Skip auto-creation for customer-added policies

    # Create structured payout with hierarchical commission structure
    StructuredPayoutService.create_for_policy(self, 'life')
  rescue StandardError => e
    Rails.logger.error "Failed to create structured payout for life insurance #{id}: #{e.message}"
  end

  def normalize_numeric_fields
    # Convert empty strings to nil for numeric fields to prevent validation errors
    self.premium_payment_term = nil if premium_payment_term.blank?
    self.policy_term = nil if policy_term.blank?
    self.net_premium = nil if net_premium.blank?
    self.total_premium = nil if total_premium.blank?
  end
end
