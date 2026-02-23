class Customer::CategoriesController < Customer::BaseController
  before_action :find_category, only: [:show]

  def index
    @categories = Category.where(status: true).order(:display_order, :name)
  end

  def show
    @products = @category.products.active
                        .includes(:approved_reviews, :stock_batches)
                        .page(params[:page]).per(12)

    # Apply sorting
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
  end

  private

  def find_category
    @category = Category.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_categories_path, alert: 'Category not found.'
  end
end