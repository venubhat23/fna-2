class Customer < ApplicationRecord
  include PgSearch::Model

  # Associations
  has_many :family_members, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :corporate_members, dependent: :destroy
  has_many :documents, class_name: 'CustomerDocument', dependent: :destroy
  has_many :uploaded_documents, as: :documentable, class_name: 'Document', dependent: :destroy
  has_one_attached :profile_image
  has_one_attached :personal_image
  has_one_attached :house_image
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

  # E-commerce associations
  has_many :bookings, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :booking_schedules, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :family_members, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :corporate_members, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :documents, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :uploaded_documents, allow_destroy: true, reject_if: :all_blank

  # Password support for customer login (temporarily using plain text storage)
  # has_secure_password

  # Custom password handling until password_digest column is added
  attr_accessor :password, :password_confirmation

  # Validate password presence and confirmation
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_required?
  validates_confirmation_of :password, if: :password_required?

  # Store password in auto_generated_password field for now
  before_save :store_password_in_auto_generated_field, if: :password_required?

  def password_required?
    password.present? || new_record?
  end

  def store_password_in_auto_generated_field
    if password.present?
      self.auto_generated_password = password
    end
  end

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile, presence: true, uniqueness: true
  validates :status, inclusion: { in: [true, false] }
  validates :whatsapp_number, format: { with: /\A[+]?[\d\s\-\(\)]{7,15}\z/ }, allow_blank: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_blank: true

  # Set default values
  after_initialize :set_defaults
  # before_create :generate_lead_id_if_missing  # Commented out until lead_id column exists

  def set_defaults
    self.status = true if status.nil?
  end

  # Optional validations
  validates :gender, inclusion: { in: ['Male', 'Female', 'Other'] }, allow_blank: true
  validates :pan_no, format: { with: /\A[A-Z]{5}\d{4}[A-Z]\z/ }, allow_blank: true

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }

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
    "#{first_name} #{middle_name} #{last_name}".strip.squeeze(' ')
  end

  def display_name
    full_name
  end

  def active?
    status
  end

  def has_location?
    latitude.present? && longitude.present?
  end

  def whatsapp_same_as_mobile?
    whatsapp_number == mobile
  end

  def self.generate_random_password(length = 10)
    charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9') + ['@', '#', '$', '%', '&']
    password = Array.new(length) { charset.sample }.join

    # Ensure it has at least one uppercase, one lowercase, one digit, and one special char
    password[0] = Array('A'..'Z').sample
    password[1] = Array('a'..'z').sample
    password[2] = Array('0'..'9').sample
    password[3] = ['@', '#', '$', '%', '&'].sample

    # Shuffle to randomize position
    password.chars.shuffle.join
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
  # def generate_lead_id_if_missing
  #   return if lead_id.present?
  #
  #   loop do
  #     self.lead_id = "CUST-#{Date.current.strftime('%Y%m%d')}-#{rand(1000..9999)}"
  #     break unless Customer.exists?(lead_id: self.lead_id) || Lead.exists?(lead_id: self.lead_id)
  #   end
  # end

end
