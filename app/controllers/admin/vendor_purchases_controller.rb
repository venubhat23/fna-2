class Admin::VendorPurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vendor_purchase, only: [:show, :edit, :update, :destroy, :complete_purchase]
  before_action :set_vendors_and_products, only: [:new, :edit, :create, :update]
  layout 'application'

  def index
    @vendor_purchases = VendorPurchase.includes(:vendor, :vendor_purchase_items, :products)
                                     .recent
    @vendor_purchases = @vendor_purchases.joins(:vendor).where('vendors.name ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @vendor_purchases = @vendor_purchases.where(vendor_id: params[:vendor_id]) if params[:vendor_id].present?
    @vendor_purchases = @vendor_purchases.where(status: params[:status]) if params[:status].present?
    @vendor_purchases = @vendor_purchases.page(params[:page]).per(20)

    @vendors = Vendor.active.order(:name)
  end

  def show
    @stock_batches = @vendor_purchase.stock_batches.includes(:product)
  end

  def new
    @vendor_purchase = VendorPurchase.new
    @vendor_purchase.vendor_purchase_items.build
  end

  def edit
    @vendor_purchase.vendor_purchase_items.build if @vendor_purchase.vendor_purchase_items.empty?
  end

  def create
    @vendor_purchase = VendorPurchase.new(vendor_purchase_params)
    @vendor_purchase.status = 'pending'

    if @vendor_purchase.save
      redirect_to admin_vendor_purchase_path(@vendor_purchase),
                  notice: 'Purchase was successfully created and stock batches have been generated.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @vendor_purchase.can_be_edited?
      if @vendor_purchase.update(vendor_purchase_params)
        redirect_to admin_vendor_purchase_path(@vendor_purchase),
                    notice: 'Purchase was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to admin_vendor_purchase_path(@vendor_purchase),
                  alert: 'Cannot edit completed or cancelled purchases.'
    end
  end

  def destroy
    if @vendor_purchase.can_be_cancelled?
      # Mark associated stock batches as cancelled before deletion
      @vendor_purchase.stock_batches.update_all(status: 'cancelled')
      @vendor_purchase.destroy
      redirect_to admin_vendor_purchases_path, notice: 'Purchase was successfully deleted.'
    else
      redirect_to admin_vendor_purchase_path(@vendor_purchase),
                  alert: 'Cannot delete completed purchases with stock movements.'
    end
  end

  def complete_purchase
    if @vendor_purchase.status == 'pending'
      @vendor_purchase.update(status: 'completed')
      redirect_to admin_vendor_purchase_path(@vendor_purchase),
                  notice: 'Purchase marked as completed.'
    else
      redirect_to admin_vendor_purchase_path(@vendor_purchase),
                  alert: 'Purchase cannot be completed.'
    end
  end

  def batch_inventory
    @stock_batches = StockBatch.includes(:product, :vendor, :vendor_purchase)
                              .active
                              .order(:batch_date, :created_at)

    @stock_batches = @stock_batches.joins(:product).where('products.name ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @stock_batches = @stock_batches.where(vendor_id: params[:vendor_id]) if params[:vendor_id].present?
    @stock_batches = @stock_batches.where('quantity_remaining > 0') if params[:in_stock] == 'true'
    @stock_batches = @stock_batches.page(params[:page]).per(50)

    @vendors = Vendor.active.order(:name)
    @total_batches = @stock_batches.count
    @total_products = @stock_batches.joins(:product).distinct.count('products.id')
    @total_stock_value = StockBatch.active.sum { |batch| batch.quantity_remaining * batch.purchase_price }
  end

  private

  def set_vendor_purchase
    @vendor_purchase = VendorPurchase.find(params[:id])
  end

  def set_vendors_and_products
    @vendors = Vendor.active.order(:name)
    @products = Product.active.order(:name)
  end

  def vendor_purchase_params
    params.require(:vendor_purchase).permit(:vendor_id, :purchase_date, :notes, :status,
      vendor_purchase_items_attributes: [
        :id, :product_id, :quantity, :purchase_price, :selling_price, :_destroy
      ]
    )
  end
end
