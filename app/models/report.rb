class Report < ApplicationRecord
  validates :name, presence: true
  validates :report_type, presence: true

  enum :report_type, {
    commission: 'commission',
    expired_insurance: 'expired_insurance',
    payment_due: 'payment_due',
    upcoming_renewal: 'upcoming_renewal',
    upcoming_payment: 'upcoming_payment',
    leads: 'leads',
    sessions: 'sessions'
  }

  scope :active, -> { where(status: true) }
  scope :recent, -> { order(created_at: :desc) }

  def self.generate_commission_report(date_range = '30_days')
    start_date = case date_range
                 when '7_days' then 7.days.ago
                 when '30_days' then 30.days.ago
                 when '3_months' then 3.months.ago
                 when '6_months' then 6.months.ago
                 when '1_year' then 1.year.ago
                 else 30.days.ago
                 end

    {
      total_commission: Policy.where(created_at: start_date..Time.current).sum(:total_premium) * 0.1,
      commission_by_agent: User.where(user_type: ['agent', 'sub_agent'])
                               .joins(:policies)
                               .where(policies: { created_at: start_date..Time.current })
                               .group('users.first_name', 'users.last_name')
                               .sum('policies.total_premium * 0.1')
    }
  rescue => e
    Rails.logger.error "Error generating commission report: #{e.message}"
    { total_commission: 0, commission_by_agent: {} }
  end

  def self.generate_expired_insurance_report
    Policy.where('end_date < ?', Date.current)
          .includes(:customer, :insurance_company)
          .order(:end_date)
  rescue => e
    Rails.logger.error "Error generating expired insurance report: #{e.message}"
    Policy.none
  end

  def self.generate_payment_due_report
    Policy.active
          .where('end_date > ? AND end_date <= ?', Date.current, 30.days.from_now)
          .includes(:customer)
          .order(:end_date)
  rescue => e
    Rails.logger.error "Error generating payment due report: #{e.message}"
    Policy.none
  end
end