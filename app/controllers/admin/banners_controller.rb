class Admin::BannersController < Admin::ApplicationController
  before_action :set_banner, only: [:show, :edit, :update, :destroy, :toggle_status]

  # GET /admin/banners
  def index
    @banners = Banner.includes(banner_image_attachment: :blob)
                    .order(:display_order, :created_at)
                    .page(params[:page]).per(25)

    # Filter by status if specified
    case params[:status]
    when 'active'
      @banners = @banners.active
    when 'inactive'
      @banners = @banners.inactive
    when 'current'
      @banners = @banners.current
    end

    # Filter by location if specified
    if params[:location].present?
      @banners = @banners.by_location(params[:location])
    end

    # Statistics for dashboard cards
    @stats = {
      total_banners: Banner.count,
      active_banners: Banner.active.count,
      current_banners: Banner.current.count,
      expired_banners: Banner.where('display_end_date < ?', Date.current).count
    }
  end

  # GET /admin/banners/1
  def show
  end

  # GET /admin/banners/new
  def new
    @banner = Banner.new
    @banner.display_start_date = Date.current
    @banner.display_end_date = 1.month.from_now
    @banner.display_order = (Banner.maximum(:display_order) || 0) + 1
  end

  # GET /admin/banners/1/edit
  def edit
  end

  # POST /admin/banners
  def create
    @banner = Banner.new(banner_params)

    if @banner.save
      redirect_to admin_banner_path(@banner), notice: 'Banner was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/banners/1
  def update
    if @banner.update(banner_params)
      redirect_to admin_banner_path(@banner), notice: 'Banner was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/banners/1
  def destroy
    @banner.destroy
    redirect_to admin_banners_path, notice: 'Banner was successfully deleted.'
  end

  # PATCH /admin/banners/1/toggle_status
  def toggle_status
    @banner.update(status: !@banner.status)
    status_text = @banner.status? ? 'activated' : 'deactivated'
    redirect_to admin_banners_path, notice: "Banner was successfully #{status_text}."
  end

  private

  def set_banner
    @banner = Banner.find(params[:id])
  end

  def banner_params
    params.require(:banner).permit(
      :title, :description, :redirect_link, :display_start_date, :display_end_date,
      :display_location, :status, :display_order, :banner_image
    )
  end
end