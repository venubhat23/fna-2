class Customer < ApplicationRecord
  include PgSearch::Model

  # Associations
  has_many :family_members, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :corporate_members, dependent: :destroy
  has_many :documents, class_name: 'CustomerDocument', dependent: :destroy
  has_many :uploaded_documents, as: :documentable, class_name: 'Document', dependent: :destroy
  has_one_attached :profile_image
  belongs_to :affiliate, class_name: 'SubAgent', foreign_key: 'sub_agent_id', optional: true

  # Insurance associations
  has_many :health_insurances, dependent: :destroy
  has_many :life_insurances, dependent: :destroy
  has_many :motor_insurances, dependent: :destroy

  # New product associations
  has_many :investments, dependent: :destroy
  has_many :loans, dependent: :destroy
  has_many :tax_services, dependent: :destroy
  has_many :travel_packages, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :family_members, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :corporate_members, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :documents, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :uploaded_documents, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :customer_type, presence: true, inclusion: { in: ['individual', 'corporate'] }

  # Individual Customer Required Fields
  validates :first_name, presence: true, if: :individual?
  validates :last_name, presence: true, if: :individual?
  validates :mobile, presence: true, if: :individual?
  validates :mobile, uniqueness: true, allow_blank: true, if: :individual?

  # Corporate Customer Required Fields
  validates :company_name, presence: true, if: :corporate?
  validates :mobile, presence: true, if: :corporate?
  validates :mobile, uniqueness: true, allow_blank: true, if: :corporate?
  validates :gst_no, presence: true, if: :corporate?

  # Validations
  validates :status, inclusion: { in: [true, false] }

  # Set default values
  after_initialize :set_defaults
  before_create :generate_lead_id_if_missing

  def set_defaults
    self.status = true if status.nil?
  end

  # Email validations - different rules for individual vs corporate
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :corporate?
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true, if: :individual?

  # Optional validations
  validates :gender, inclusion: { in: ['male', 'female', 'other'] }, allow_blank: true
  validates :marital_status, inclusion: { in: ['single', 'married', 'divorced', 'widowed'] }, allow_blank: true
  validates :pan_no, format: { with: /\A[A-Z]{5}\d{4}[A-Z]\z/ }, allow_blank: true
  validates :gst_no, format: { with: /\A\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z\d][A-Z\d]\z/ }, allow_blank: true

  # Enums
  enum :customer_type, { individual: 'individual', corporate: 'corporate' }

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }
  scope :individuals, -> { where(customer_type: 'individual') }
  scope :corporates, -> { where(customer_type: 'corporate') }

  # Callbacks
  before_validation :normalize_blank_values
  before_save :calculate_age

  # Search
  pg_search_scope :search_customers,
    against: [:first_name, :last_name, :company_name, :email, :mobile, :pan_no],
    using: {
      tsearch: { prefix: true, any_word: true }
    }

  # Instance methods
  def full_name
    if individual?
      "#{first_name} #{middle_name} #{last_name}".strip.squeeze(' ')
    else
      company_name
    end
  end

  def display_name
    individual? ? full_name : company_name
  end

  def active?
    status
  end

  def individual?
    customer_type == 'individual'
  end

  def corporate?
    customer_type == 'corporate'
  end


  # Cache busting callback
  after_update :bust_cache

  def calculate_age
    if birth_date.present?
      today = Date.current
      birth = birth_date

      # Calculate years
      years = today.year - birth.year

      # Calculate if birthday hasn't occurred this year yet
      if today.month < birth.month || (today.month == birth.month && today.day < birth.day)
        years -= 1
      end

      # Store numeric age for compatibility
      self.age = years
    end
  end

  def formatted_age
    if birth_date.present?
      today = Date.current
      birth = birth_date

      # Calculate years
      years = today.year - birth.year

      # Calculate if birthday hasn't occurred this year yet
      if today.month < birth.month || (today.month == birth.month && today.day < birth.day)
        years -= 1
      end

      # Calculate the last birthday and days
      if years == 0
        # If less than a year old, calculate days from birth
        days = (today - birth).to_i
        "#{days} days"
      else
        # Calculate days since last birthday
        last_birthday = Date.new(today.year, birth.month, birth.day)
        if last_birthday > today
          last_birthday = Date.new(today.year - 1, birth.month, birth.day)
        end

        days = (today - last_birthday).to_i

        # Format the age string
        if days == 0
          "#{years} years"
        else
          "#{years} years, #{days} days"
        end
      end
    else
      ""
    end
  end

  private

  def bust_cache
    Rails.cache.delete("customer_#{id}_full_name")
    Rails.cache.delete("customer_#{id}_display_name")
  end

  def normalize_blank_values
    # Convert empty strings to nil to prevent uniqueness validation issues
    self.mobile = nil if mobile.blank?
    self.email = nil if email.blank?
    self.pan_no = nil if pan_no.blank?
    self.gst_no = nil if gst_no.blank?
  end

  # Generate lead_id if not already present (for direct customer creation)
  def generate_lead_id_if_missing
    return if lead_id.present?

    loop do
      self.lead_id = "CUST-#{Date.current.strftime('%Y%m%d')}-#{rand(1000..9999)}"
      break unless Customer.exists?(lead_id: self.lead_id) || Lead.exists?(lead_id: self.lead_id)
    end
  end

end
