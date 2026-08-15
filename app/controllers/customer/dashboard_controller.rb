class Customer::DashboardController < Customer::BaseController
  def index
    # Categories for the category cards section
    @categories = Category.active_ordered_by_display.first(8)

    # Featured products for showcase - prioritize products with images and good stock
    @featured_products = Product.includes(:category)
                                .where(status: 'active')
                                .where('stock > 0')
                                .order(created_at: :desc)
                                .limit(4)

    # Popular products - could be based on sales or manually marked as popular
    @popular_products = Product.includes(:category)
                               .where(status: 'active')
                               .where('stock > 0')
                               .order(:stock)
                               .limit(4)

    # Customer's cart count for the action cards (using pending booking items as cart)
    pending_booking = current_customer&.bookings&.where(status: 'pending')&.first
    @cart_items_count = pending_booking&.booking_items&.sum(:quantity) || 0

    # Customer's recent orders count
    @recent_orders_count = current_customer&.bookings&.where('created_at > ?', 30.days.ago)&.count || 0

    # Customer's active subscriptions count
    @active_subscriptions_count = current_customer&.milk_subscriptions&.where(is_active: true)&.count || 0

    # Customer's recent bookings for reference
    @recent_bookings = current_customer&.bookings&.order(created_at: :desc)&.limit(3) || []

    # Active subscriptions for reference
    @active_subscriptions = current_customer&.milk_subscriptions&.where(is_active: true)&.limit(3) || []

    # Chart data for Order Activity (Last 7 days)
    @order_activity_data = build_order_activity_data

    # Chart data for Monthly Spending (This year)
    @monthly_spending_data = build_monthly_spending_data

    # Banners (if still needed)
    @banners = Banner.cached_homepage_banners
  end

  private

  def build_order_activity_data
    # Get order counts for last 7 days - one query over the whole window instead of
    # one per day, bucketed in Ruby (same approach as Affiliate::DashboardController#index).
    window_start = (Date.current - 7.days).beginning_of_day
    window_end = Date.current.end_of_day
    booking_dates = current_customer&.bookings
                                 &.where(booking_date: window_start..window_end)
                                 &.pluck(:booking_date) || []

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
    current_year = Date.current.year
    year_start = Date.new(current_year, 1, 1).beginning_of_day
    year_end = Date.new(current_year, 12, 31).end_of_day
    booking_rows = current_customer&.bookings
                                 &.where(booking_date: year_start..year_end)
                                 &.where.not(total_amount: nil)
                                 &.pluck(:booking_date, :total_amount) || []

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