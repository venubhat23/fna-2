class Customer::DashboardController < Customer::BaseController
  def index
    @featured_products = Product.where(status: 'active').limit(8)
    @categories = Category.where(status: true).order(:display_order, :name).limit(6)
    @recent_orders = current_customer.orders.order(created_at: :desc).limit(3)
    @active_subscriptions = current_customer.milk_subscriptions.where(is_active: true).limit(3)
    @banners = Banner.where(status: true, display_location: 'homepage')
                     .where('display_start_date <= ? AND (display_end_date IS NULL OR display_end_date >= ?)',
                            Date.current, Date.current)
                     .order(:display_order)
  end
end