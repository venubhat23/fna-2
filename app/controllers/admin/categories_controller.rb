class Admin::CategoriesController < Admin::ApplicationController
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
    products_count = @category.products.count

    if products_count > 0
      # Delete all products in this category first
      @category.products.destroy_all
      flash_message = "Category '#{@category.name}' and #{products_count} product(s) have been deleted successfully."
    else
      flash_message = "Category '#{@category.name}' was successfully deleted."
    end

    # Safely remove the category and its image
    @category.image.purge_later if @category.image.attached?
    @category.destroy

    redirect_to admin_categories_path, notice: flash_message
  end

  # Cloudinary upload action - mirrors Admin::ProductsController#upload_cloudinary_image.
  # Categories use Cloudinary (not Active Storage) because the production host has an
  # ephemeral filesystem, so disk-backed Active Storage uploads do not survive a redeploy.
  def upload_cloudinary_image
    respond_to do |format|
      if params[:image].present?
        begin
          result = Cloudinary::Uploader.upload(
            params[:image].tempfile,
            folder: 'categories',
            public_id: "category-#{SecureRandom.hex(8)}",
            overwrite: true,
            resource_type: :auto,
            transformation: [
              { width: 1200, height: 1200, crop: :limit, quality: :auto, fetch_format: :auto }
            ]
          )

          format.json {
            render json: {
              success: true,
              public_id: result['public_id'],
              url: result['secure_url'],
              thumbnail_url: Cloudinary::Utils.cloudinary_url(result['public_id'], width: 300, height: 300, crop: :fill)
            }
          }
        rescue => e
          Rails.logger.error "Cloudinary category upload failed: #{e.message}"
          format.json {
            render json: { success: false, error: "Upload failed: #{e.message}" }, status: :unprocessable_entity
          }
        end
      else
        format.json { render json: { success: false, error: "No image provided" }, status: :bad_request }
      end
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
    params.require(:category).permit(:name, :description, :image, :image_url, :status, :display_order)
  end
end