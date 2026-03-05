class Customer::DashboardController < Customer::BaseController
  def index
    # Categories for the category cards section
    @categories = Category.where(status: true).order(:display_order, :name).limit(8)

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
    @banners = Banner.where(status: true, display_location: 'homepage')
                     .where('display_start_date <= ? AND (display_end_date IS NULL OR display_end_date >= ?)',
                            Date.current, Date.current)
                     .order(:display_order)
  end

  private

  def build_order_activity_data
    # Get order counts for last 7 days
    order_data = []
    labels = []

    7.downto(0) do |days_ago|
      date = Date.current - days_ago.days
      labels << date.strftime('%a')

      orders_count = current_customer&.bookings
                                   &.where(booking_date: date.beginning_of_day..date.end_of_day)
                                   &.count || 0
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
    # Get spending data for current year by month
    spending_data = []
    labels = []
    current_year = Date.current.year

    (1..12).each do |month|
      labels << Date::MONTHNAMES[month][0, 3] # Jan, Feb, etc.

      month_start = Date.new(current_year, month, 1)
      month_end = month_start.end_of_month

      # Calculate total spending for this month
      monthly_total = current_customer&.bookings
                                    &.where(booking_date: month_start..month_end)
                                    &.where.not(total_amount: nil)
                                    &.sum(:total_amount) || 0

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