class Affiliate::DashboardController < Affiliate::BaseController
  def index
    @affiliate = current_affiliate

    # Dashboard statistics
    @total_bookings = Booking.joins(:customer).where(customers: { sub_agent_id: @affiliate.id }).count
    @pending_bookings = Booking.joins(:customer).where(customers: { sub_agent_id: @affiliate.id }, status: 'pending').count
    @completed_bookings = Booking.joins(:customer).where(customers: { sub_agent_id: @affiliate.id }, status: 'delivered').count
    @total_revenue = Booking.joins(:customer).where(customers: { sub_agent_id: @affiliate.id }, payment_status: 'paid').sum(:total_amount)

    # Commission statistics (if commission system exists)
    begin
      @total_commission = CommissionPayout.where(affiliate_id: @affiliate.id).sum(:affiliate_commission_amount)
      @pending_commission = CommissionPayout.where(affiliate_id: @affiliate.id, status: 'pending').sum(:affiliate_commission_amount)
    rescue
      @total_commission = 0
      @pending_commission = 0
    end

    # Recent bookings
    @recent_bookings = Booking.joins(:customer)
                             .where(customers: { sub_agent_id: @affiliate.id })
                             .includes(:customer)
                             .order(created_at: :desc)
                             .limit(5)

    # Monthly revenue chart data (last 6 months)
    @monthly_revenue = []
    6.downto(0) do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = i.months.ago.end_of_month
      revenue = Booking.joins(:customer)
                      .where(customers: { sub_agent_id: @affiliate.id })
                      .where(payment_status: 'paid')
                      .where(created_at: month_start..month_end)
                      .sum(:total_amount)
      @monthly_revenue << {
        month: month_start.strftime('%b %Y'),
        revenue: revenue
      }
    end

    # Booking status distribution
    @booking_statuses = Booking.joins(:customer)
                              .where(customers: { sub_agent_id: @affiliate.id })
                              .group(:status)
                              .count
  end
end