class Franchise::DashboardController < Franchise::BaseController
  def index
    @franchise = current_franchise

    # Dashboard statistics
    @total_bookings = Booking.joins(:customer).where(customers: { franchise_id: @franchise.id }).count
    @pending_bookings = Booking.joins(:customer).where(customers: { franchise_id: @franchise.id }, status: 'pending').count
    @completed_bookings = Booking.joins(:customer).where(customers: { franchise_id: @franchise.id }, status: 'delivered').count
    @total_revenue = Booking.joins(:customer).where(customers: { franchise_id: @franchise.id }, payment_status: 'paid').sum(:total_amount)

    # Recent bookings
    @recent_bookings = Booking.joins(:customer)
                             .where(customers: { franchise_id: @franchise.id })
                             .includes(:customer)
                             .order(created_at: :desc)
                             .limit(5)

    # Monthly revenue chart data (last 6 months)
    @monthly_revenue = []
    6.downto(0) do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = i.months.ago.end_of_month
      revenue = Booking.joins(:customer)
                      .where(customers: { franchise_id: @franchise.id })
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
                              .where(customers: { franchise_id: @franchise.id })
                              .group(:status)
                              .count
  end
end