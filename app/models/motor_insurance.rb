class MotorInsurance < ApplicationRecord
  include PgSearch::Model
  include InsuranceCompanyConstants

  # Associations
  belongs_to :customer, counter_cache: :policies_count
  belongs_to :sub_agent, class_name: 'SubAgent', optional: true
  belongs_to :distributor, optional: true
  belongs_to :investor, optional: true
  belongs_to :agency_code, optional: true
  belongs_to :broker, optional: true
  has_many_attached :documents
  has_many_attached :policy_documents

  # Validations
  validates :policy_holder, presence: true
  validates :insurance_company_name, presence: true
  validates :vehicle_type, presence: true, inclusion: { in: ['New Vehicle', 'Old Vehicle'] }
  validates :class_of_vehicle, presence: true, inclusion: { in: ['Private Car', 'Two Wheeler', 'Goods Vehicle', 'Taxi', 'Bus'] }
  validates :insurance_type, presence: true, inclusion: { in: ['Comprehensive', 'Third Party', 'Own Damage'] }
  validates :policy_number, presence: true, uniqueness: true
  validates :policy_booking_date, presence: true
  validates :policy_start_date, presence: true
  validates :policy_end_date, presence: true
  validates :registration_number, presence: true
  validates :vehicle_idv, presence: true, numericality: { greater_than: 0 }
  validates :tp_premium, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :net_premium, presence: true, numericality: { greater_than: 0 }
  validates :gst_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_premium, presence: true, numericality: { greater_than: 0 }

  # Custom validations
  validate :company_name_must_be_valid
  validate :tp_premium_required_for_tp_policy

  # Enums for dropdowns
  VEHICLE_TYPES = ['New Vehicle', 'Old Vehicle'].freeze
  CLASS_OF_VEHICLES = ['Private Car', 'Two Wheeler', 'Goods Vehicle', 'Taxi', 'Bus'].freeze
  INSURANCE_TYPES = ['Comprehensive', 'Third Party', 'Own Damage'].freeze
  POLICY_TYPES = ['New', 'Renewal'].freeze
  PAYOUT_OPTIONS = ['OD', 'TP', 'Net'].freeze

  # Scopes
  scope :active, -> { where('policy_end_date >= ?', Date.current) }
  scope :expired, -> { where('policy_end_date < ?', Date.current) }
  scope :expiring_soon, -> { where(policy_end_date: Date.current..30.days.from_now) }

  # Search
  pg_search_scope :search_motor_policies,
    against: [:policy_number, :registration_number, :insurance_company_name, :make, :model],
    associated_against: {
      customer: [:first_name, :last_name, :company_name]
    },
    using: {
      tsearch: { prefix: true, any_word: true }
    }

  # Callbacks
  before_save :calculate_totals
  before_save :set_total_idv
  after_save :set_notification_dates
  before_create :inherit_customer_lead_id
  after_create :create_commission_payouts
  after_create :create_lead_record

  # Instance methods
  def active?
    policy_end_date >= Date.current
  end

  def expired?
    policy_end_date < Date.current
  end

  def expiring_soon?
    policy_end_date.between?(Date.current, 30.days.from_now)
  end

  def days_until_expiry
    (policy_end_date - Date.current).to_i
  end

  def client_name
    customer.display_name
  end

  def policy_holder_options
    options = [['Self', 'Self']]
    if customer&.family_members&.any?
      customer.family_members.each do |member|
        options << [member.full_name, member.id.to_s]
      end
    end
    options
  end

  def affiliate_name
    sub_agent ? sub_agent.display_name : 'Self'
  end

  def notifications_due_today
    return [] unless notification_dates.present?

    notification_list = JSON.parse(notification_dates)
    today = Date.current.to_s

    notification_list.select { |notification| notification['date'] == today }
  end

  def self.all_notifications_due_today
    notifications = []

    all.each do |insurance|
      insurance.notifications_due_today.each do |notification|
        notifications << {
          id: "#{insurance.id}_#{notification['type']}",
          type: notification['type'],
          title: notification['title'],
          message: notification['message'],
          date: notification['date'],
          insurance_id: insurance.id,
          insurance_type: 'motor'
        }
      end
    end

    notifications
  end

  private

  def calculate_totals
    if net_premium.present? && gst_percentage.present?
      gst_amount = net_premium * (gst_percentage / 100.0)
      self.total_premium = net_premium + gst_amount
    end

    # Calculate main agent commission (legacy fields)
    if net_premium.present? && main_agent_commission_percent.present?
      self.main_agent_commission_amount = net_premium * (main_agent_commission_percent / 100.0)
    end

    if main_agent_commission_amount.present? && main_agent_tds_percent.present?
      self.main_agent_tds_amount = main_agent_commission_amount * (main_agent_tds_percent / 100.0)
      self.after_tds_value = main_agent_commission_amount - main_agent_tds_amount
    end

    # Calculate enhanced commission structure
    calculate_enhanced_commissions
  end

  def calculate_enhanced_commissions
    return unless net_premium.present?

    # Main Agent Commission (new structure)
    if main_agent_commission_percentage.present?
      self.commission_amount = (net_premium * main_agent_commission_percentage / 100.0).round(2)

      if tds_percentage.present?
        self.tds_amount = (commission_amount * tds_percentage / 100.0).round(2)
        # Note: after_tds_value is already calculated above for legacy compatibility
      end
    end

    # Sub Agent Commission
    if sub_agent_commission_percentage.present?
      self.sub_agent_commission_amount = (net_premium * sub_agent_commission_percentage / 100.0).round(2)

      if sub_agent_tds_percentage.present?
        self.sub_agent_tds_amount = (sub_agent_commission_amount * sub_agent_tds_percentage / 100.0).round(2)
        self.sub_agent_after_tds_value = sub_agent_commission_amount - sub_agent_tds_amount
      end
    end

    # Distributor Commission (Affiliate)
    if distributor_commission_percentage.present?
      self.distributor_commission_amount = (net_premium * distributor_commission_percentage / 100.0).round(2)

      if distributor_tds_percentage.present?
        self.distributor_tds_amount = (distributor_commission_amount * distributor_tds_percentage / 100.0).round(2)
        self.distributor_after_tds_value = distributor_commission_amount - distributor_tds_amount
      end
    end

    # Ambassador Commission
    if ambassador_commission_percentage.present?
      self.ambassador_commission_amount = (net_premium * ambassador_commission_percentage / 100.0).round(2)

      if ambassador_tds_percentage.present?
        self.ambassador_tds_amount = (ambassador_commission_amount * ambassador_tds_percentage / 100.0).round(2)
        self.ambassador_after_tds_value = ambassador_commission_amount - ambassador_tds_amount
      end
    end

    # Investor Commission
    if investor_commission_percentage.present?
      self.investor_commission_amount = (net_premium * investor_commission_percentage / 100.0).round(2)

      if investor_tds_percentage.present?
        self.investor_tds_amount = (investor_commission_amount * investor_tds_percentage / 100.0).round(2)
        self.investor_after_tds_value = investor_commission_amount - investor_tds_amount
      end
    end

    # Calculate total distribution percentage
    distribution_percentages = [
      sub_agent_commission_percentage,
      distributor_commission_percentage,
      ambassador_commission_percentage,
      investor_commission_percentage
    ].compact.sum

    self.total_distribution_percentage = distribution_percentages.round(2)

    # Calculate profit
    if main_agent_commission_percentage.present? && company_expenses_percentage.present?
      self.profit_percentage = (main_agent_commission_percentage - total_distribution_percentage - company_expenses_percentage).round(2)
      self.profit_amount = (net_premium * profit_percentage / 100.0).round(2)
    end
  end

  def set_total_idv
    vehicle_amount = vehicle_idv || 0
    cng_amount = cng_idv || 0
    self.total_idv = vehicle_amount + cng_amount
  end

  def company_name_must_be_valid
    return if insurance_company_name.blank?
    # Skip validation for customer-added policies (they can input any company name)
    return if is_customer_added

    unless self.class.insurance_company_names.include?(insurance_company_name)
      errors.add(:insurance_company_name, "must be a valid insurance company")
    end
  end

  def tp_premium_required_for_tp_policy
    if insurance_type == 'Third Party' && tp_premium.blank?
      errors.add(:tp_premium, "is required for Third Party policies")
    end
  end

  def set_notification_dates
    return unless policy_end_date.present? && (saved_change_to_policy_end_date? || notification_dates.blank?)

    notification_schedule = []

    # 1 month before expiry
    one_month_before = policy_end_date - 30.days
    notification_schedule << {
      type: 'renewal',
      title: 'Policy Renewal Reminder - 1 Month',
      message: "Your motor policy (#{policy_number}) is due for renewal on #{policy_end_date.strftime('%d %b %Y')}. Please renew to continue your coverage.",
      date: one_month_before.to_s
    }

    # 15 days before expiry
    fifteen_days_before = policy_end_date - 15.days
    notification_schedule << {
      type: 'renewal',
      title: 'Policy Renewal Reminder - 15 Days',
      message: "Your motor policy (#{policy_number}) expires in 15 days on #{policy_end_date.strftime('%d %b %Y')}. Please renew to avoid coverage gap.",
      date: fifteen_days_before.to_s
    }

    # 7 days before expiry
    seven_days_before = policy_end_date - 7.days
    notification_schedule << {
      type: 'renewal',
      title: 'Policy Renewal Reminder - 1 Week',
      message: "Your motor policy (#{policy_number}) expires in 1 week on #{policy_end_date.strftime('%d %b %Y')}. Immediate action required.",
      date: seven_days_before.to_s
    }

    # 1 day before expiry
    one_day_before = policy_end_date - 1.day
    notification_schedule << {
      type: 'renewal',
      title: 'Policy Renewal Reminder - Final Notice',
      message: "Your motor policy (#{policy_number}) expires tomorrow on #{policy_end_date.strftime('%d %b %Y')}. Renew now to avoid coverage gap.",
      date: one_day_before.to_s
    }

    # Only include future dates
    future_notifications = notification_schedule.select { |n| Date.parse(n[:date]) >= Date.current }

    update_column(:notification_dates, future_notifications.to_json) if future_notifications.any?
  end

  def create_commission_payouts
    # Commission payouts are now handled by StructuredPayoutService in create_structured_payout
    # This method is kept for backward compatibility but does nothing to avoid duplicates
    Rails.logger.info "Commission payouts handled by StructuredPayoutService for motor insurance #{id}"
  end

  def create_lead_record
    return if lead_id.present? # Skip if lead already exists
    return if is_customer_added? # Skip auto-creation for customer-added policies

    LeadGeneratorService.create_lead_for_insurance(self)
  rescue StandardError => e
    Rails.logger.error "Failed to create lead for motor insurance #{id}: #{e.message}"
  end

  def inherit_customer_lead_id
    return if lead_id.present? || customer.nil?

    self.lead_id = customer.lead_id if customer.lead_id.present?
  end
end
