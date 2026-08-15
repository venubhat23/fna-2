class Admin::VendorsController < Admin::ApplicationController
  before_action :authenticate_user!
  before_action :set_vendor, only: [:show, :edit, :update, :destroy, :toggle_status]
  layout 'application'

  def index
    @vendors = Vendor.includes(:vendor_purchases)
                    .order(created_at: :desc)
    @vendors = @vendors.where('name ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @vendors = @vendors.where(status: params[:status]) if params[:status].present?

    # Single GROUP BY for the stat cards instead of 2 separate COUNT queries
    # (the view previously called @vendors.count and @vendors.active.count directly).
    vendor_status_counts = @vendors.except(:includes, :order).group(:status).count
    @total_vendors_count = vendor_status_counts.values.sum
    @active_vendors_count = vendor_status_counts[true].to_i

    # Purchases/outstanding stat cards must reflect ALL vendors matching the
    # current filter, not just the current page — computed here via SQL
    # aggregates on the pre-pagination scope (the view previously called
    # @vendors.sum(&:total_purchases)/(&:outstanding_balance) on the already-
    # paginated 20-row relation, which was both wrong and triggered a
    # per-vendor query since Vendor#total_purchases sums via association).
    totals = @vendors.except(:includes, :order)
                     .joins(:vendor_purchases)
                     .pick(Arel.sql('SUM(vendor_purchases.total_amount)'), Arel.sql('SUM(vendor_purchases.paid_amount)'))
    total_purchases_sum = totals&.first.to_f
    total_paid_sum = totals&.last.to_f
    total_opening_balance_sum = @vendors.except(:includes, :order).sum(:opening_balance).to_f
    @total_purchases_sum = total_purchases_sum
    @total_outstanding_sum = total_purchases_sum - total_paid_sum + total_opening_balance_sum

    @vendors = @vendors.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.json { render json: @vendors }
    end
  end

  def show
    @purchases = @vendor.vendor_purchases.includes(:vendor_purchase_items).recent.limit(10)
    @stock_summary = InventoryService.new.vendor_stock_summary(@vendor.id)
  end

  def new
    @vendor = Vendor.new
  end

  def edit
  end

  def create
    @vendor = Vendor.new(vendor_params)

    if @vendor.save
      redirect_to admin_vendor_path(@vendor),
                  notice: 'Vendor was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @vendor.update(vendor_params)
      redirect_to admin_vendor_path(@vendor),
                  notice: 'Vendor was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @vendor.can_be_deleted?
      @vendor.destroy
      redirect_to admin_vendors_path, notice: 'Vendor was successfully deleted.'
    else
      redirect_to admin_vendor_path(@vendor),
                  alert: 'Cannot delete vendor with existing purchases.'
    end
  end

  def toggle_status
    @vendor.update(status: !@vendor.status)
    status_text = @vendor.status? ? 'activated' : 'deactivated'

    respond_to do |format|
      format.html {
        redirect_to admin_vendors_path,
        notice: "Vendor was successfully #{status_text}."
      }
      format.json {
        render json: {
          status: 'success',
          message: "Vendor #{status_text} successfully",
          new_status: @vendor.status
        }
      }
    end
  end

  private

  def set_vendor
    @vendor = Vendor.find(params[:id])
  end

  def vendor_params
    params.require(:vendor).permit(:name, :phone, :email, :address,
                                   :payment_type, :opening_balance, :status)
  end
end
