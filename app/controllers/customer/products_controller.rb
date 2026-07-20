class Customer::ProductsController < Customer::BaseController
  before_action :find_product, only: [:show]

  def index
    # LEFT JOIN + cached_stock aggregate so in_stock?/low_stock?/stock_status in the view
    # (called per product in the list) read a pre-computed column instead of re-querying
    # stock_batches for every row. See Product#total_batch_stock / #cached_total_batch_stock.
    @products = Product.active
                        .joins("LEFT JOIN stock_batches ON stock_batches.product_id = products.id AND stock_batches.status = 'active'")
                        .select("products.*, COALESCE(SUM(stock_batches.quantity_remaining), 0) AS cached_stock")
                        .group("products.id")
                        .includes(:category, :approved_reviews)

    # Apply filters
    @products = @products.by_category(params[:category_id]) if params[:category_id].present?
    @products = @products.search(params[:search]) if params[:search].present?

    # Price range filter
    if params[:min_price].present? && params[:max_price].present?
      @products = @products.where(price: params[:min_price]..params[:max_price])
    end

    # Stock filter (reuses the LEFT JOIN above instead of joining stock_batches again)
    case params[:stock_filter]
    when 'in_stock'
      @products = @products.having('SUM(stock_batches.quantity_remaining) > 0')
    when 'out_of_stock'
      @products = @products.having('COALESCE(SUM(stock_batches.quantity_remaining), 0) = 0')
    end

    # Sort
    case params[:sort]
    when 'price_low_to_high'
      @products = @products.order(:price)
    when 'price_high_to_low'
      @products = @products.order(price: :desc)
    when 'name_a_to_z'
      @products = @products.order(:name)
    when 'name_z_to_a'
      @products = @products.order(name: :desc)
    when 'newest'
      @products = @products.order(created_at: :desc)
    else
      @products = @products.order(:name)
    end

    @products = @products.page(params[:page]).per(12)

    # For filters
    @categories = Category.where(status: true).order(:name)
    @price_ranges = [
      { label: 'Under ₹100', min: 0, max: 100 },
      { label: '₹100 - ₹500', min: 100, max: 500 },
      { label: '₹500 - ₹1000', min: 500, max: 1000 },
      { label: 'Above ₹1000', min: 1000, max: Float::INFINITY }
    ]
  end

  def show
    @related_products = Product.active
                              .joins("LEFT JOIN stock_batches ON stock_batches.product_id = products.id AND stock_batches.status = 'active'")
                              .select("products.*, COALESCE(SUM(stock_batches.quantity_remaining), 0) AS cached_stock")
                              .group("products.id")
                              .includes(:category, :approved_reviews)
                              .where.not(id: @product.id)
                              .where(category: @product.category)
                              .limit(4)
    @reviews = @product.approved_reviews.recent.limit(10)
  end

  def search
    @products = Product.active.search(params[:q])
    @products = @products.page(params[:page]).per(12)
    @search_term = params[:q]
  end

  def category
    @category = Category.find(params[:id])
    @products = @category.products.active
                          .joins("LEFT JOIN stock_batches ON stock_batches.product_id = products.id AND stock_batches.status = 'active'")
                          .select("products.*, COALESCE(SUM(stock_batches.quantity_remaining), 0) AS cached_stock")
                          .group("products.id")
                          .includes(:approved_reviews)
    @products = @products.page(params[:page]).per(12)
  end

  private

  def find_product
    @product = Product.active
                       .joins("LEFT JOIN stock_batches ON stock_batches.product_id = products.id AND stock_batches.status = 'active'")
                       .select("products.*, COALESCE(SUM(stock_batches.quantity_remaining), 0) AS cached_stock")
                       .group("products.id")
                       .includes(:category, :approved_reviews)
                       .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_products_path, alert: 'Product not found.'
  end
end