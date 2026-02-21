class Admin::VendorPurchasesController < Admin::ApplicationController
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
      Rails.logger.error "VendorPurchase creation failed: #{@vendor_purchase.errors.full_messages.join(', ')}"
      flash.now[:alert] = "Error creating purchase: #{@vendor_purchase.errors.full_messages.join(', ')}"
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
    respond_to do |format|
      format.html do
        # GET request - show confirmation page or redirect if not valid
        if @vendor_purchase.status != 'pending'
          redirect_to admin_vendor_purchase_path(@vendor_purchase),
                      alert: 'Purchase cannot be completed.'
          return
        end
        # If it's a valid pending purchase, render confirmation page or redirect to show
        redirect_to admin_vendor_purchase_path(@vendor_purchase),
                    notice: 'Purchase ready to be completed.'
      end

      format.json do
        # PATCH/POST request - actually complete the purchase
        if @vendor_purchase.status == 'pending'
          @vendor_purchase.update(status: 'completed')
          render json: { success: true, message: 'Purchase marked as completed.' }
        else
          render json: { success: false, message: 'Purchase cannot be completed.' }
        end
      end
    end

    # Handle PATCH/POST requests for non-AJAX
    if request.patch? || request.post?
      if @vendor_purchase.status == 'pending'
        @vendor_purchase.update(status: 'completed')
        redirect_to admin_vendor_purchase_path(@vendor_purchase),
                    notice: 'Purchase marked as completed.'
      else
        redirect_to admin_vendor_purchase_path(@vendor_purchase),
                    alert: 'Purchase cannot be completed.'
      end
    end
  end

  def batch_inventory
    # Get all stock batches with filters
    stock_batches_query = StockBatch.includes(:product, :vendor, :vendor_purchase)
                                   .order(:batch_date, :created_at)

    stock_batches_query = stock_batches_query.joins(:product).where('products.name ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    stock_batches_query = stock_batches_query.where(vendor_id: params[:vendor_id]) if params[:vendor_id].present?
    # Apply in_stock filter only if explicitly requested
    if params[:in_stock] == 'true'
      stock_batches_query = stock_batches_query.where('quantity_remaining > 0')
    elsif params[:in_stock] == 'false'
      stock_batches_query = stock_batches_query.where('quantity_remaining <= 0')
    end
    # If no in_stock filter, show all batches

    @stock_batches = stock_batches_query.to_a

    # Group batches by product for better organization
    @products_with_batches = @stock_batches.group_by(&:product)

    # Statistics
    @vendors = Vendor.active.order(:name)
    @total_batches = @stock_batches.count
    @total_products = @products_with_batches.keys.count
    @total_stock_value = @stock_batches.sum { |batch| batch.quantity_remaining * batch.purchase_price }
    @total_quantity = @stock_batches.sum(&:quantity_remaining)

    # Product-level statistics (sorted by product name)
    @product_stats = @products_with_batches.sort_by { |product, _| product.name }.map do |product, batches|
      total_quantity = batches.sum(&:quantity_remaining)
      total_value = batches.sum { |batch| batch.quantity_remaining * batch.purchase_price }
      avg_purchase_price = total_quantity > 0 ? (total_value / total_quantity.to_f) : 0

      {
        product: product,
        batch_count: batches.count,
        total_quantity: total_quantity,
        total_value: total_value,
        avg_purchase_price: avg_purchase_price,
        oldest_batch_date: batches.min_by(&:batch_date)&.batch_date,
        newest_batch_date: batches.max_by(&:batch_date)&.batch_date,
        vendor_count: batches.map(&:vendor).uniq.count,
        batches: batches.sort_by(&:batch_date)
      }
    end
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
    params.require(:vendor_purchase).permit(:vendor_id, :purchase_date, :notes, :status, :paid_amount,
      vendor_purchase_items_attributes: [
        :id, :product_id, :quantity, :purchase_price, :selling_price, :_destroy
      ]
    )
  end
end
