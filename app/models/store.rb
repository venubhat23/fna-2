class Store < ApplicationRecord
  # Constants
  MAX_STORES_LIMIT = 10

  # Associations
  has_many :bookings, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :address, presence: true, length: { maximum: 500 }
  validates :city, presence: true, length: { maximum: 50 }
  validates :state, presence: true, length: { maximum: 50 }
  validates :pincode, presence: true, format: { with: /\A\d{6}\z/, message: "should be 6 digits" }
  validates :contact_mobile, presence: true, format: { with: /\A[6-9]\d{9}\z/, message: "should be a valid Indian mobile number" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :contact_person, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true

  # Custom validation for maximum stores limit
  validate :check_maximum_stores_limit, on: :create

  # Numbers pasted from a phone often carry spaces, dashes, or a +91/91/0 country
  # prefix (e.g. "+91 98765 43210") - strip that noise before validating so a
  # genuinely valid 10-digit number isn't rejected just for its formatting.
  before_validation :normalize_contact_mobile

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }
  scope :by_display_order, -> { order(:name) }

  # Class methods
  def self.available_for_collection
    active.by_display_order
  end

  def self.can_add_more_stores?
    Store.count < MAX_STORES_LIMIT
  end

  def self.remaining_store_slots
    MAX_STORES_LIMIT - Store.count
  end

  # Instance methods
  def display_name
    "#{name} - #{city}"
  end

  def full_address
    [address, city, state, pincode].compact.join(', ')
  end

  def contact_info
    info = [contact_person, contact_mobile]
    info << email if email.present?
    info.join(' | ')
  end

  def can_be_deleted?
    bookings.count == 0
  end

  private

  def normalize_contact_mobile
    return if contact_mobile.blank?

    cleaned = contact_mobile.to_s.gsub(/[\s\-()]/, '')
    cleaned = cleaned.sub(/\A(\+91|91|0)(?=\d{10}\z)/, '')
    self.contact_mobile = cleaned
  end

  def check_maximum_stores_limit
    if Store.count >= MAX_STORES_LIMIT
      errors.add(:base, "Maximum #{MAX_STORES_LIMIT} stores allowed. Cannot add more stores.")
    end
  end
end
