class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  validates :setting_type, presence: true

  # Business details validations
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :upi_id, format: { with: /\A[a-zA-Z0-9.\-_]+@[a-zA-Z0-9.\-_]+\z/, message: "must be a valid UPI ID" }, allow_blank: true

  # Class method to get a setting value by key
  def self.get_value(key)
    setting = find_by(key: key)
    setting&.value
  end

  # Class method to set a setting value by key
  def self.set_value(key, value, description: nil, setting_type: 'string')
    setting = find_or_initialize_by(key: key)
    setting.value = value
    setting.description = description if description
    setting.setting_type = setting_type
    setting.save!
    setting
  end

  # Get company expenses percentage as float
  def self.company_expenses_percentage
    value = get_value('company_expenses_percentage')
    value ? value.to_f : 2.0
  end

  # Set company expenses percentage
  def self.set_company_expenses_percentage(percentage)
    set_value(
      'company_expenses_percentage',
      percentage.to_s,
      description: 'Company expenses percentage that can be configured by admin',
      setting_type: 'percentage'
    )
  end

  # Get default pagination per page as integer
  def self.default_pagination_per_page
    value = get_value('default_pagination_per_page')
    value ? value.to_i : 10
  end

  # Set default pagination per page
  def self.set_default_pagination_per_page(per_page)
    set_value(
      'default_pagination_per_page',
      per_page.to_s,
      description: 'Default number of records per page for all index pages',
      setting_type: 'integer'
    )
  end

  # Commission methods for new columns

  # Get default main agent commission as float
  def self.default_main_agent_commission
    setting = find_by(key: 'system_config')
    setting&.default_main_agent_commission || 0.0
  end

  # Get default affiliate commission as float
  def self.default_affiliate_commission
    setting = find_by(key: 'system_config')
    setting&.default_affiliate_commission || 0.0
  end

  # Get default ambassador commission as float
  def self.default_ambassador_commission
    setting = find_by(key: 'system_config')
    setting&.default_ambassador_commission || 0.0
  end

  # Get default company expenses as float
  def self.default_company_expenses
    setting = find_by(key: 'system_config')
    setting&.default_company_expenses || 0.0
  end

  # Update commission values
  def self.update_commission_settings(params)
    # Create a default setting if none exists
    setting = find_by(key: 'system_config') || create!(
      key: 'system_config',
      value: 'system configuration',
      setting_type: 'configuration',
      description: 'System configuration settings'
    )

    setting.update!(
      default_main_agent_commission: params[:default_main_agent_commission],
      default_affiliate_commission: params[:default_affiliate_commission],
      default_ambassador_commission: params[:default_ambassador_commission],
      default_company_expenses: params[:default_company_expenses]
    )
  end

  # Business Settings Methods

  # Singleton pattern to get the current business settings
  def self.business_settings
    find_by(key: 'business_config') || new
  end

  # Update business settings
  def self.update_business_settings(params)
    setting = find_or_create_by(key: 'business_config') do |s|
      s.value = 'business configuration'
      s.setting_type = 'configuration'
      s.description = 'Business configuration settings'
    end

    setting.update!(
      business_name: params[:business_name],
      address: params[:address],
      mobile: params[:mobile],
      email: params[:email],
      gstin: params[:gstin],
      pan_number: params[:pan_number],
      account_holder_name: params[:account_holder_name],
      bank_name: params[:bank_name],
      account_number: params[:account_number],
      ifsc_code: params[:ifsc_code],
      upi_id: params[:upi_id],
      terms_and_conditions: params[:terms_and_conditions]
    )

    setting
  end

  def formatted_terms_and_conditions
    return [] if terms_and_conditions.blank?
    terms_and_conditions.split("\n").map(&:strip).reject(&:empty?)
  end
end
