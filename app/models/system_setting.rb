class SystemSetting < ApplicationRecord
  # In-process cache, not Rails.cache: Rails.cache is Solid Cache in this app, which
  # stores entries in the same Postgres database (see database.yml's `cache:` connection)
  # - fetching through it would just trade one DB round trip for another. This setting is
  # read on nearly every admin/customer/franchise index page load, so a real in-memory
  # cache is what actually avoids the extra round trip.
  LOCAL_CACHE = ActiveSupport::Cache::MemoryStore.new

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
  # Cached since this is queried on nearly every admin/customer/franchise index page load
  # (a dozen+ call sites) - an uncached lookup here means an extra DB round trip per request.
  def self.default_pagination_per_page
    LOCAL_CACHE.fetch('system_setting_default_pagination_per_page', expires_in: 10.minutes) do
      value = get_value('default_pagination_per_page')
      value ? value.to_i : 10
    end
  end

  # Set default pagination per page
  def self.set_default_pagination_per_page(per_page)
    setting = set_value(
      'default_pagination_per_page',
      per_page.to_s,
      description: 'Default number of records per page for all index pages',
      setting_type: 'integer'
    )
    LOCAL_CACHE.delete('system_setting_default_pagination_per_page')
    setting
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

  # Collect From Store Feature Methods

  # Check if collect from store feature is enabled
  def self.collect_from_store_enabled?
    setting = find_by(key: 'system_config')
    setting&.collect_from_store_enabled || false
  end

  # Enable or disable collect from store feature
  def self.set_collect_from_store_enabled(enabled)
    setting = find_or_create_by(key: 'system_config') do |s|
      s.value = 'system configuration'
      s.setting_type = 'configuration'
      s.description = 'System configuration settings'
    end

    setting.update!(collect_from_store_enabled: enabled)
    setting
  end

  # Update collect from store setting along with other settings
  def self.update_collect_from_store_settings(params)
    setting = find_or_create_by(key: 'system_config') do |s|
      s.value = 'system configuration'
      s.setting_type = 'configuration'
      s.description = 'System configuration settings'
    end

    setting.update!(collect_from_store_enabled: params[:collect_from_store_enabled] || false)
    setting
  end
end
