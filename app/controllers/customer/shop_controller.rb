class Customer::ShopController < Customer::BaseController
  def index
    @categories = Category.where(status: true).order(:display_order, :name)

    # Filter products based on parameters
    @products = Product.where(status: 'active')

    # Category filter
    if params[:category_id].present?
      @selected_category = Category.find(params[:category_id])
      @products = @products.where(category_id: params[:category_id])
    end

    # Search filter
    if params[:search].present?
      @search_query = params[:search]
      @products = @products.where("name ILIKE ? OR description ILIKE ?",
                                  "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Price range filter
    if params[:min_price].present?
      @products = @products.where("price >= ?", params[:min_price].to_f)
    end

    if params[:max_price].present?
      @products = @products.where("price <= ?", params[:max_price].to_f)
    end

    # Product type filter
    if params[:product_type].present? && params[:product_type] != 'all'
      @products = @products.where(product_type: params[:product_type])
    end

    # Sorting
    case params[:sort]
    when 'price_low'
      @products = @products.order(:price)
    when 'price_high'
      @products = @products.order(price: :desc)
    when 'name'
      @products = @products.order(:name)
    when 'newest'
      @products = @products.order(created_at: :desc)
    else
      @products = @products.order(:display_order, :name)
    end

    # Pagination
    @products = @products.page(params[:page]).per(12)

    # Get banners for shop page
    @banners = Banner.where(status: true, display_location: ['shop', 'homepage'])
                     .where('display_start_date <= ? AND (display_end_date IS NULL OR display_end_date >= ?)',
                            Date.current, Date.current)
                     .order(:display_order)
                     .limit(3)
  end

  def category
    @category = Category.find(params[:id])
    @products = @category.products.where(status: 'active')

    # Apply same filtering logic as index
    if params[:search].present?
      @search_query = params[:search]
      @products = @products.where("name ILIKE ? OR description ILIKE ?",
                                  "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Price range filter
    if params[:min_price].present?
      @products = @products.where("price >= ?", params[:min_price].to_f)
    end

    if params[:max_price].present?
      @products = @products.where("price <= ?", params[:max_price].to_f)
    end

    # Sorting
    case params[:sort]
    when 'price_low'
      @products = @products.order(:price)
    when 'price_high'
      @products = @products.order(price: :desc)
    when 'name'
      @products = @products.order(:name)
    when 'newest'
      @products = @products.order(created_at: :desc)
    else
      @products = @products.order(:display_order, :name)
    end

    @products = @products.page(params[:page]).per(12)
  end

  def product
    @product = Product.find(params[:id])
    @related_products = Product.where(category_id: @product.category_id)
                               .where.not(id: @product.id)
                               .where(status: 'active')
                               .limit(4)
  end
end