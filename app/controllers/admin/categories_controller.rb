class Admin::CategoriesController < ApplicationController
  before_action :set_category, only: [:show, :edit, :update, :destroy, :toggle_status]
  before_action :authenticate_user!

  def index
    @categories = Category.includes(:products)
                         .order(:display_order, :name)

    if params[:search].present?
      @categories = @categories.where('name ILIKE ?', "%#{params[:search]}%")
    end

    if params[:status].present?
      @categories = @categories.where(status: params[:status] == 'active')
    end

    @categories = @categories.page(params[:page]).per(20)
  end

  def show
    @products = @category.products.includes(:category).recent.limit(10)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_category_path(@category), notice: 'Category was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_category_path(@category), notice: 'Category was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.products.exists?
      redirect_to admin_categories_path, alert: 'Cannot delete category with products. Please reassign or delete products first.'
    else
      # Safely remove the category and its image
      @category.image.purge_later if @category.image.attached?
      @category.destroy
      redirect_to admin_categories_path, notice: 'Category was successfully deleted.'
    end
  end

  def toggle_status
    @category.update(status: !@category.status)
    respond_to do |format|
      format.json { render json: { status: @category.status, message: "Category #{@category.status? ? 'activated' : 'deactivated'} successfully" } }
      format.html { redirect_to admin_categories_path, notice: "Category #{@category.status? ? 'activated' : 'deactivated'} successfully" }
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :description, :image, :status, :display_order)
  end
end