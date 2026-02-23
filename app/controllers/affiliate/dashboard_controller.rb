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
    @monthly_referrals = []
    6.downto(0) do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = i.months.ago.end_of_month
      total = current_affiliate.referrals.where(created_at: month_start..month_end).count
      converted = current_affiliate.referrals.where(created_at: month_start..month_end, status: 'converted').count

      @monthly_referrals << {
        month: month_start.strftime('%b %Y'),
        total: total,
        converted: converted
      }
    end

    # Referral status distribution
    @status_distribution = current_affiliate.referrals.group(:status).count
  end
end