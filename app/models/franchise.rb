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
  validates :contact_person_name, presence: true
  validates :business_type, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :pincode, presence: true, format: { with: /\A\d{6}\z/ }
  validates :pan_no, format: { with: /\A[A-Z]{5}\d{4}[A-Z]\z/ }, allow_blank: true
  validates :gst_no, format: { with: /\A\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}\z/ }, allow_blank: true
  validates :status, inclusion: { in: [true, false] }
  validates :commission_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :franchise_fee, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :whatsapp_number, format: { with: /\A[+]?[\d\s\-\(\)]{7,15}\z/ }, allow_blank: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_blank: true

  # Set default values
  after_initialize :set_defaults

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
end
