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

    # Banners (if still needed)
    @banners = Banner.where(status: true, display_location: 'homepage')
                     .where('display_start_date <= ? AND (display_end_date IS NULL OR display_end_date >= ?)',
                            Date.current, Date.current)
                     .order(:display_order)
  end
end