class Affiliate::BookingsController < Affiliate::BaseController
  before_action :set_booking, only: [:show, :update]

  def index
    @bookings = Booking.joins(:customer)
                      .where(customers: { sub_agent_id: current_affiliate.id })
                      .includes(:customer, :booking_items)
                      .order(created_at: :desc)

    # Filter by status if provided
    if params[:status].present?
      @bookings = @bookings.where(status: params[:status])
    end

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @bookings = @bookings.where(
        "booking_number ILIKE ? OR customers.first_name ILIKE ? OR customers.last_name ILIKE ? OR customers.email ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    @bookings = @bookings.page(params[:page]).per(20)

    # Stats for the page
    @total_count = Booking.joins(:customer).where(customers: { sub_agent_id: current_affiliate.id }).count
    @pending_count = Booking.joins(:customer).where(customers: { sub_agent_id: current_affiliate.id }, status: 'pending').count
    @processing_count = Booking.joins(:customer).where(customers: { sub_agent_id: current_affiliate.id }, status: 'processing').count
    @delivered_count = Booking.joins(:customer).where(customers: { sub_agent_id: current_affiliate.id }, status: 'delivered').count
  end

  def show
    @customer = @booking.customer
    @booking_items = @booking.booking_items.includes(product: :category)
  end

  def new
    @booking = Booking.new
    @booking.booking_items.build

    @customers = Customer.where(sub_agent_id: current_affiliate.id).order(:first_name, :last_name)

    @products = Product.active
                       .includes(:category, :stock_batches, :product_variants,
                                 image_attachment: :blob, additional_images_attachments: :blob)
                       .joins("LEFT JOIN stock_batches ON stock_batches.product_id = products.id AND stock_batches.status = 'active' AND stock_batches.quantity_remaining > 0")
                       .select("products.*, COALESCE(SUM(stock_batches.quantity_remaining), 0) as cached_stock")
                       .group("products.id")
                       .order(:name)
  end

  def create
    @booking = Booking.new(create_booking_params)
    @booking.booked_by = 'affiliate'
    @booking.booking_date = @booking.booking_date.presence || Time.current

    unless @booking.customer_id.present? && Customer.where(sub_agent_id: current_affiliate.id, id: @booking.customer_id).exists?
      @booking.errors.add(:customer_id, 'must be one of your referred customers')
      render_new_with_errors
      return
    end

    unless validate_stock_availability(@booking)
      render_new_with_errors
      return
    end

    if @booking.save
      redirect_to affiliate_booking_path(@booking), notice: 'Booking created successfully!'
    else
      render_new_with_errors
    end
  end

  def update
    if @booking.update(booking_params)
      redirect_to affiliate_booking_path(@booking), notice: 'Booking updated successfully'
    else
      redirect_to affiliate_booking_path(@booking), alert: 'Failed to update booking'
    end
  end

  private

  def render_new_with_errors
    @customers = Customer.where(sub_agent_id: current_affiliate.id).order(:first_name, :last_name)
    @products = Product.active.includes(:category, :product_variants, image_attachment: :blob, additional_images_attachments: :blob)
    flash.now[:alert] = @booking.errors.full_messages.join(', ')
    render :new, status: :unprocessable_entity
  end

  def set_booking
    @booking = Booking.joins(:customer)
                     .where(customers: { sub_agent_id: current_affiliate.id })
                     .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to affiliate_bookings_path, alert: 'Booking not found'
  end

  def booking_params
    params.require(:booking).permit(:status, :notes)
  end

  def create_booking_params
    params.require(:booking).permit(
      :customer_id, :booking_date, :notes, :customer_name, :customer_email,
      :customer_phone, :delivery_address, :payment_method, :payment_status, :discount_amount,
      booking_items_attributes: [:id, :product_id, :product_variant_id, :quantity, :price, :_destroy]
    )
  end

  # Mirrors Franchise::BookingsController#validate_stock_availability
  def validate_stock_availability(booking)
    active_items = booking.booking_items.reject(&:marked_for_destruction?)

    products_by_id = Product.where(id: active_items.map(&:product_id)).index_by(&:id)
    variant_ids = active_items.map(&:product_variant_id).compact
    variants_by_id = ProductVariant.where(id: variant_ids).index_by(&:id)

    active_items.each do |item|
      product = products_by_id[item.product_id] || Product.find(item.product_id)

      if product.has_multiple_quantities? && item.product_variant_id.present?
        variant = variants_by_id[item.product_variant_id]
        available_stock = variant ? variant.available_stock.to_f : 0.0
      else
        available_stock = product.available_stock
      end

      if item.quantity > available_stock
        booking.errors.add(:base, "Insufficient stock for #{product.name}. Available: #{available_stock}, Requested: #{item.quantity}")
        return false
      end
    end
    true
  end
end