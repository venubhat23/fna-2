class Distributor < ApplicationRecord
  include PgSearch::Model

  # Associations
  has_many :distributor_documents, dependent: :destroy
  has_many :uploaded_documents, as: :documentable, class_name: 'Document', dependent: :destroy
  has_many :distributor_assignments, dependent: :destroy
  has_many :assigned_sub_agents, through: :distributor_assignments, source: :sub_agent
  has_many :sub_agents, dependent: :nullify
  has_one_attached :upload_main_document

  # Nested attributes for documents
  accepts_nested_attributes_for :distributor_documents, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :uploaded_documents, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :mobile, presence: true,
            uniqueness: {
              message: "number is already registered with another ambassador",
              case_sensitive: false
            }
  validates :email, presence: true,
            uniqueness: {
              message: "address is already registered with another ambassador",
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
  validate :ensure_unique_across_affiliates

  # Default values
  before_validation :set_default_role_id, on: :create

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

  private

  def set_default_role_id
    self.role_id ||= 'distributor'
  end

  def ensure_unique_across_affiliates
    # Check if email exists in SubAgent table
    if email.present?
      existing_sub_agent = SubAgent.where(email: email)
      existing_sub_agent = existing_sub_agent.where.not(id: self.id) if persisted?
      if existing_sub_agent.exists?
        errors.add(:email, "address is already registered with an affiliate")
      end
    end

    # Check if mobile exists in SubAgent table
    if mobile.present?
      existing_sub_agent = SubAgent.where(mobile: mobile)
      existing_sub_agent = existing_sub_agent.where.not(id: self.id) if persisted?
      if existing_sub_agent.exists?
        errors.add(:mobile, "number is already registered with an affiliate")
      end
    end
  end
end
