class SubAgent < ApplicationRecord
  include PgSearch::Model

  # Password authentication
  has_secure_password

  # Create alias for backward compatibility - use Affiliate instead
  def self.inherited(subclass)
    super
    if subclass.name == 'Affiliate'
      # Don't create circular inheritance
      return
    end
  end

  # Store plain password for display purposes
  attr_accessor :store_plain_password
  before_save :store_password_if_changed

  # Associations
  belongs_to :role
  has_many :sub_agent_documents, dependent: :destroy
  has_many :uploaded_documents, as: :documentable, class_name: 'Document', dependent: :destroy
  has_one :distributor_assignment, dependent: :destroy
  has_one :assigned_distributor, through: :distributor_assignment, source: :distributor
  belongs_to :distributor, optional: true
  has_one_attached :upload_main_document
  has_many :customers, foreign_key: 'sub_agent_id'

  # Nested attributes for documents
  accepts_nested_attributes_for :sub_agent_documents, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :uploaded_documents, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :mobile, presence: true,
            uniqueness: {
              message: "number is already registered with another affiliate",
              case_sensitive: false
            }
  validates :email, presence: true,
            uniqueness: {
              message: "address is already registered with another affiliate",
              case_sensitive: false
            },
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              message: "format is invalid"
            }
  validates :role_id, presence: true
  validates :gender, inclusion: { in: ['Male', 'Female', 'Other'] }, allow_blank: true
  validates :account_type, inclusion: { in: ['Savings', 'Current', 'Salary'] }, allow_blank: true

  # Custom validations
  validate :ensure_unique_across_distributors

  # Enums
  enum :status, { active: 0, inactive: 1 }

  # Search configuration
  pg_search_scope :search_by_name_mobile_email,
                  against: [:first_name, :last_name, :mobile, :email],
                  using: {
                    tsearch: { prefix: true }
                  }

  # Instance methods
  def full_name
    "#{first_name} #{middle_name} #{last_name}".strip
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def formatted_mobile
    mobile.presence || "N/A"
  end

  def formatted_email
    email.presence || "N/A"
  end

  def age
    if birth_date.present?
      age = Date.current.year - birth_date.year
      age -= 1 if Date.current < birth_date + age.years
      age
    else
      nil
    end
  end

  private

  def store_password_if_changed
    if password.present? && (password_digest_changed? || new_record?)
      self.plain_password = password
      self.original_password = password if new_record?
      # Also update original_password on password change if it's blank
      self.original_password = password if self.original_password.blank?
    end
  end

  def ensure_unique_across_distributors
    # Check if email exists in Distributor table
    if email.present?
      existing_distributor = Distributor.where(email: email)
      existing_distributor = existing_distributor.where.not(id: self.id) if persisted?
      if existing_distributor.exists?
        errors.add(:email, "address is already registered with an ambassador")
      end
    end

    # Check if mobile exists in Distributor table
    if mobile.present?
      existing_distributor = Distributor.where(mobile: mobile)
      existing_distributor = existing_distributor.where.not(id: self.id) if persisted?
      if existing_distributor.exists?
        errors.add(:mobile, "number is already registered with an ambassador")
      end
    end
  end
end