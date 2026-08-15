class Franchise::DashboardController < Franchise::BaseController
  def index
    # Get bookings for the current franchise
    # Since bookings are associated with franchises, not users directly
    @bookings = current_franchise.bookings.includes(:customer, :booking_items)

    # Analytics data - one grouped query for counts, one for sums, instead of
    # ~10 separate per-status count/sum queries
    status_counts = @bookings.group(:status).count
    status_sums = @bookings.group(:status).sum(:total_amount)

    @total_bookings = status_counts.values.sum
    @draft_bookings = status_counts['draft'] || 0
    @pending_bookings = status_counts['ordered_and_delivery_pending'] || 0
    @confirmed_bookings = status_counts['confirmed'] || 0
    @processing_bookings = %w[processing packed].sum { |s| status_counts[s] || 0 }
    @shipped_bookings = %w[shipped out_for_delivery].sum { |s| status_counts[s] || 0 }
    @delivered_bookings = %w[delivered completed].sum { |s| status_counts[s] || 0 }
    @cancelled_bookings = %w[cancelled returned].sum { |s| status_counts[s] || 0 }

    # Revenue analytics
    @total_revenue = %w[delivered completed].sum { |s| status_sums[s] || 0 }
    @pending_revenue = status_sums.reject { |s, _| %w[cancelled returned].include?(s) }.values.sum
    @this_month_revenue = @bookings.where(
      status: [:delivered, :completed],
      created_at: Date.current.beginning_of_month..Date.current.end_of_month
    ).sum(:total_amount) || 0

    # Today's statistics
    @today_bookings = @bookings.where(created_at: Date.current.all_day).count
    @today_revenue = @bookings.where(
      status: [:delivered, :completed],
      created_at: Date.current.all_day
    ).sum(:total_amount) || 0

    # Recent bookings
    @recent_bookings = @bookings.recent.limit(5)

    # Average order value - reuse the aggregates computed above instead of 2-3 more queries
    @average_order_value = @delivered_bookings > 0 ? (@total_revenue / @delivered_bookings) : 0
  end
end