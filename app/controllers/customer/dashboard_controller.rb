class Customer::DashboardController < Customer::BaseController
  def index
    customer = current_customer
    if customer
      # All of this page's queries are started async so their round trips to the
      # remote DB overlap, then read back with .value.

      # Customer's cart count for the action cards (using pending booking items as cart)
      # - the first pending booking (by id, as .first did) is picked in a subquery.
      pending_booking_id = customer.bookings.where(status: 'pending').order(:id).limit(1).select(:id)
      cart_items_count = BookingItem.where(booking_id: pending_booking_id).async_sum(:quantity)

      # Customer's recent orders count
      recent_orders_count = customer.bookings.where('created_at > ?', 30.days.ago).async_count

      # Customer's active subscriptions count
      active_subscriptions_count = customer.milk_subscriptions.where(is_active: true).async_count

      # Booking dates/amounts for both charts in one query (last 8 days + this year)
      booking_rows = customer.bookings
                             .where(booking_date: order_activity_window)
                             .or(customer.bookings.where(booking_date: monthly_spending_window))
                             .async_pluck(:booking_date, :total_amount)

      @cart_items_count = cart_items_count.value || 0
      @recent_orders_count = recent_orders_count.value
      @active_subscriptions_count = active_subscriptions_count.value
      @booking_chart_rows = booking_rows.value
    else
      @cart_items_count = @recent_orders_count = @active_subscriptions_count = 0
      @booking_chart_rows = []
    end

    # Chart data for Order Activity (Last 7 days)
    @order_activity_data = build_order_activity_data

    # Chart data for Monthly Spending (This year)
    @monthly_spending_data = build_monthly_spending_data
  end

  private

  def order_activity_window
    (Date.current - 7.days).beginning_of_day..Date.current.end_of_day
  end

  def monthly_spending_window
    current_year = Date.current.year
    Date.new(current_year, 1, 1).beginning_of_day..Date.new(current_year, 12, 31).end_of_day
  end

  def build_order_activity_data
    # Get order counts for last 7 days - one query over the whole window instead of
    # one per day, bucketed in Ruby (same approach as Affiliate::DashboardController#index).
    window = order_activity_window
    booking_dates = @booking_chart_rows.filter_map { |booking_date, _| booking_date if window.cover?(booking_date) }

    order_data = []
    labels = []

    7.downto(0) do |days_ago|
      date = Date.current - days_ago.days
      labels << date.strftime('%a')

      orders_count = booking_dates.count { |booking_date| booking_date && booking_date.to_date == date }
      order_data << orders_count
    end

    # If no data exists, provide sample data with message
    if order_data.sum == 0
      {
        labels: labels,
        data: [0, 0, 0, 0, 0, 0, 0],
        has_data: false,
        message: 'No orders in the last 7 days'
      }
    else
      {
        labels: labels,
        data: order_data,
        has_data: true,
        message: nil
      }
    end
  end

  def build_monthly_spending_data
    # Get spending data for current year by month - one query over the whole year
    # instead of one per month, bucketed in Ruby (same approach as
    # Affiliate::DashboardController#index).
    window = monthly_spending_window
    booking_rows = @booking_chart_rows.select { |booking_date, total_amount| total_amount && window.cover?(booking_date) }

    spending_data = []
    labels = []

    (1..12).each do |month|
      labels << Date::MONTHNAMES[month][0, 3] # Jan, Feb, etc.

      # Calculate total spending for this month
      monthly_total = booking_rows.select { |booking_date, _total_amount| booking_date && booking_date.month == month }
                                   .sum { |_booking_date, total_amount| total_amount }

      spending_data << monthly_total.to_f
    end

    # If no data exists, provide sample data with message
    if spending_data.sum == 0
      {
        labels: labels,
        data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        has_data: false,
        message: 'No spending data for this year'
      }
    else
      {
        labels: labels,
        data: spending_data,
        has_data: true,
        message: nil
      }
    end
  end
end