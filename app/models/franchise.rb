class Franchise < ApplicationRecord
  include PgSearch::Model

  # Associations
  belongs_to :user, optional: true

  # Password support
  has_secure_password validations: false

  # Custom password handling for auto-generated passwords
  attr_accessor :password_confirmation

  # Store password in auto_generated_password field for display
  before_save :store_password_in_auto_generated_field, if: :password_present?

  def password_present?
    password.present?
  end

  def store_password_in_auto_generated_field
    if password.present?
      self.auto_generated_password = password
    end
  end

  # Validations
  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile, presence: true, uniqueness: true, format: { with: /\A[+]?[\d\s\-\(\)]{10,15}\z/ }
  validates :address, presence: true

  # Optional fields
  validates :contact_person_name, presence: false
  validates :business_type, presence: false
  validates :city, presence: false
  validates :state, presence: false
  validates :pincode, format: { with: /\A\d{6}\z/ }, allow_blank: true
  validates :pan_no, format: { with: /\A[A-Z]{5}\d{4}[A-Z]\z/ }, allow_blank: true
  validates :gst_no, format: { with: /\A\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}\z/ }, allow_blank: true
  validates :status, inclusion: { in: [true, false] }
  validates :commission_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_blank: true
  validates :franchise_fee, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :whatsapp_number, format: { with: /\A[+]?[\d\s\-\(\)]{7,15}\z/ }, allow_blank: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_blank: true

  # Set default values
  after_initialize :set_defaults
  after_create :create_franchise_user

  def set_defaults
    self.status = true if status.nil?
    self.commission_percentage = 10.0 if commission_percentage.nil?
  end

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }

  # Search functionality
  pg_search_scope :search_franchises,
    against: [:name, :email, :mobile, :contact_person_name, :city, :state, :pan_no],
    using: {
      tsearch: { prefix: true, any_word: true }
    }

  # Instance methods
  def display_name
    name
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

  # Callbacks
  before_validation :normalize_blank_values

  private

  def normalize_blank_values
    # Convert empty strings to nil to prevent uniqueness validation issues
    self.mobile = nil if mobile.blank?
    self.email = nil if email.blank?
    self.pan_no = nil if pan_no.blank?
    self.gst_no = nil if gst_no.blank?
  end

  def create_franchise_user
    return if user.present? # Skip if user is already associated

    # Generate password if not present
    generated_password = password.present? ? password : self.class.generate_random_password

    # Store the password in auto_generated_password field
    update_column(:auto_generated_password, generated_password)

    # Find franchise role
    franchise_role = Role.find_by(name: 'franchise')

    # Create user account for franchise
    franchise_user = User.new(
      first_name: contact_person_name.presence || name.split(' ').first || 'Franchise',
      last_name: contact_person_name.presence ? name.split(' ').last : name.split(' ').last || 'Partner',
      email: email,
      password: generated_password,
      password_confirmation: generated_password,
      mobile: mobile,
      user_type: 'franchise',
      role: 'franchise',
      role_id: franchise_role&.id,
      status: true,
      company_name: name,
      address: address,
      city: city,
      state: state,
      pincode: pincode
    )

    if franchise_user.save(validate: false)
      # Associate the user with this franchise
      update_column(:user_id, franchise_user.id)
      Rails.logger.info "✅ Created user account for franchise: #{email}"
    else
      Rails.logger.error "❌ Failed to create user for franchise #{name}: #{franchise_user.errors.full_messages}"
    end
  rescue => e
    Rails.logger.error "❌ Error creating franchise user: #{e.message}"
  end
end
