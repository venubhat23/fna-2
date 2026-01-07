class AgencyCode < ApplicationRecord
  include InsuranceCompanyConstants

  # Relationships
  belongs_to :broker, optional: true

  # Validations
  validates :insurance_type, presence: true, inclusion: { in: ['Health', 'Motor', 'Life', 'General', 'Other'] }
  validates :company_name, presence: true
  validates :agent_name, presence: true
  validates :code, presence: true, uniqueness: { scope: [:company_name, :insurance_type] }

  # Custom validation to ensure company_name is from predefined list
  validate :company_name_must_be_valid

  # Scopes for filtering
  scope :by_insurance_type, ->(type) { where(insurance_type: type) if type.present? }
  scope :by_company, ->(company) { where(company_name: company) if company.present? }
  scope :search, ->(term) { where("company_name ILIKE ? OR agent_name ILIKE ?", "%#{term}%", "%#{term}%") if term.present? }

  # Instance methods
  def display_name
    "#{company_name} - #{agent_name} (#{insurance_type})"
  end

  private

  def company_name_must_be_valid
    return if company_name.blank?

    unless self.class.insurance_company_names.include?(company_name)
      errors.add(:company_name, "must be a valid insurance company")
    end
  end
end
