class Admin::CouponsController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_coupon, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @coupons = Coupon.all
    @coupons = @coupons.search(params[:search]) if params[:search].present?
    @coupons = case params[:filter]
               when 'active' then @coupons.active
               when 'inactive' then @coupons.inactive
               when 'expired' then @coupons.expired
               when 'upcoming' then @coupons.upcoming
               else @coupons
               end
    @coupons = paginate_records(@coupons.order(created_at: :desc))

    @stats = {
      total: Coupon.count,
      active: Coupon.active.count,
      expired: Coupon.expired.count,
      upcoming: Coupon.upcoming.count
    }
  end

  def show
  end

  def new
    @coupon = Coupon.new
  end

  def edit
  end

  def create
    @coupon = Coupon.new(coupon_params)

    if @coupon.save
      redirect_to admin_coupons_path, notice: 'Coupon was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @coupon.update(coupon_params)
      redirect_to admin_coupons_path, notice: 'Coupon was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coupon.destroy
    redirect_to admin_coupons_path, notice: 'Coupon was successfully deleted.'
  end

  def toggle_status
    @coupon.update(status: !@coupon.status)
    redirect_to admin_coupons_path, notice: "Coupon status updated to #{@coupon.status ? 'Active' : 'Inactive'}."
  end

  private

  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(
      :code, :description, :discount_type, :discount_value,
      :minimum_amount, :maximum_discount, :usage_limit,
      :valid_from, :valid_until, :status,
      :applicable_products, :applicable_categories
    )
  end
end