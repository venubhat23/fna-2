class Affiliate::DashboardController < Affiliate::ApplicationController
  def index
    @stats = {
      total_referrals: current_affiliate.total_referrals,
      pending_referrals: current_affiliate.pending_referrals,
      registered_referrals: current_affiliate.registered_referrals,
      converted_referrals: current_affiliate.converted_referrals,
      conversion_rate: current_affiliate.conversion_rate
    }

    @recent_referrals = current_affiliate.referrals.recent.limit(5)

    # Monthly referral data (last 6 months)
    window_start = 6.months.ago.beginning_of_month
    rows = current_affiliate.referrals
                             .where(created_at: window_start..Time.current)
                             .pluck(:created_at, :status)

    @monthly_referrals = 6.downto(0).map do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = i.months.ago.end_of_month
      in_month = rows.select { |created_at, _status| created_at.between?(month_start, month_end) }

      {
        month: month_start.strftime('%b %Y'),
        total: in_month.size,
        converted: in_month.count { |_created_at, status| status == 'converted' }
      }
    end

    # Referral status distribution
    @status_distribution = current_affiliate.referrals.group(:status).count
  end
end