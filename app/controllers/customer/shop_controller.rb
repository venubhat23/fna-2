class Customer::ShopController < Customer::BaseController
  def index
    @booking = Booking.new
    @booking.booking_items.build

    # Get categories for filters (Category.active_ordered_by_display is already
    # backed by an in-process cache, see Category::LOCAL_CACHE)
    @categories = Category.active_ordered_by_display

    # LEFT JOIN + cached_stock aggregate so in_stock?/low_stock?/cached_total_batch_stock
    # (called per product in the view) read a pre-computed column instead of loading every
    # historical stock_batches row per product. See Product#total_batch_stock /
    # #cached_total_batch_stock and Customer::ProductsController for the same pattern.
    @products = Product.active
                      .joins("LEFT JOIN stock_batches ON stock_batches.product_id = products.id AND stock_batches.status = 'active'")
                      .select("products.*, COALESCE(SUM(stock_batches.quantity_remaining), 0) AS cached_stock")
                      .group("products.id")
                      .includes(:category, :product_variants, image_attachment: :blob)
                      .order(:display_order, :name)

    # Apply search filter if present
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @products = @products.joins(:category)
                          .where("products.name ILIKE ? OR products.sku ILIKE ? OR categories.name ILIKE ?",
                                 search_term, search_term, search_term)
    end

    # Apply category filter
    if params[:category_id].present? && params[:category_id] != ''
      @products = @products.where(category_id: params[:category_id])
    end

    # Load once here so the view's @products.count / .any? / .each in the template
    # read from the same in-memory array instead of firing a COUNT + EXISTS + SELECT.
    @products = @products.to_a

    # Get customer info if logged in
    @customer_addresses = current_customer&.customer_addresses || []
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
    @product = Product.includes(:product_variants).find(params[:id])
    @related_products = Product.where(category_id: @product.category_id)
                               .where.not(id: @product.id)
                               .where(status: 'active')
                               .includes(image_attachment: :blob)
                               .limit(4)
  end

  def success
    @booking = current_customer&.bookings&.find_by(booking_number: params[:booking_id])

    unless @booking
      flash[:error] = 'Order not found.'
      redirect_to customer_shop_path and return
    end
  end

  def cart_order
    # Create order from cart data
    cart_data = params[:cart_items] || []

    if cart_data.empty?
      render json: { error: 'Cart is empty' }, status: :unprocessable_entity
      return
    end

    begin
      ActiveRecord::Base.transaction do
        # Initialize booking with minimal attributes to avoid callbacks
        @booking = Booking.new
        @booking.customer = current_customer
        @booking.booking_date = Time.current
        @booking.customer_name = current_customer&.display_name
        @booking.customer_email = current_customer&.email
        @booking.customer_phone = current_customer&.mobile
        @booking.payment_method = params[:payment_method] || 'cod'
        @booking.booked_by = 'customer'

        # Create booking items from cart
        total_amount = 0
        cart_data.each do |item_data|
          product = Product.find(item_data[:product_id])
          quantity = item_data[:quantity].to_f
          price = item_data[:price].to_f
          variant_id = item_data[:product_variant_id].presence

          # Validate stock
          if !product.can_fulfill_order?(quantity, variant_id: variant_id)
            available = variant_id.present? ? product.product_variants.find_by(id: variant_id)&.available_stock.to_f : product.available_quantity
            render json: {
              error: "Insufficient stock for #{product.name}. Only #{available} available."
            }, status: :unprocessable_entity
            return
          end

          # Create booking item
          booking_item = @booking.booking_items.build(
            product: product,
            product_variant_id: variant_id,
            quantity: quantity,
            price: price
          )

          total_amount += (price * quantity)
        end

        # Set totals
        @booking.subtotal = total_amount
        @booking.total_amount = total_amount

        # Set status after all other attributes
        @booking.status = 'confirmed'
        @booking.payment_status = 'unpaid'

        @booking.save!

        render json: {
          success: true,
          booking_number: @booking.booking_number,
          redirect_url: customer_shop_success_path(booking_id: @booking.booking_number)
        }
      end

    rescue => e
      render json: { error: "Failed to create order: #{e.message}" }, status: :internal_server_error
    end
  end

  def create_booking
    # Initialize booking with customer information
    @booking = Booking.new(booking_params)
    @booking.customer = current_customer
    @booking.booking_date = Date.current
    @booking.booked_by = 'customer'

    # Handle customer information from form
    @booking.customer_name = params.dig(:booking, :customer_name) || current_customer&.display_name
    @booking.customer_email = params.dig(:booking, :customer_email) || current_customer&.email
    @booking.customer_phone = params.dig(:booking, :customer_phone) || current_customer&.mobile

    # Set initial status and payment status
    @booking.status = 'confirmed'
    @booking.payment_status = 'unpaid' # Default to unpaid, can be updated based on payment method

    begin
      # Process booking items from cart data
      if params[:booking_items].present?
        ActiveRecord::Base.transaction do
          params[:booking_items].each do |index, item_data|
            quantity = item_data[:quantity].to_f
            next if quantity <= 0

            product = Product.find(item_data[:product_id])
            variant_id = item_data[:product_variant_id].presence

            # Check stock availability
            if product.has_multiple_quantities? && variant_id.present?
              variant = product.product_variants.find_by(id: variant_id)
              available_stock = variant ? variant.available_stock.to_f : 0.0
            else
              available_stock = product.stock_batches.where(status: 'active').sum(:quantity_remaining) || 0
            end

            if quantity > available_stock
              flash[:error] = "Insufficient stock for #{product.name}. Only #{available_stock} available."
              redirect_to customer_shop_path and return
            end

            # Create booking item
            booking_item = @booking.booking_items.build(
              product_id: item_data[:product_id],
              product_variant_id: variant_id,
              quantity: quantity,
              price: item_data[:price].to_f
            )
          end

          # Save booking if items exist
          if @booking.booking_items.any?
            @booking.save!

            # Calculate totals after saving
            @booking.calculate_totals
            @booking.save!

            # Handle payment method specific logic
            if @booking.payment_method == 'cash'
              @booking.update(payment_status: 'unpaid')
              success_message = "Order placed successfully! Payment will be collected on delivery."
            else
              success_message = "Order placed successfully! Booking number: #{@booking.booking_number}"
            end

            # Successful order creation - redirect to success page with booking ID
            redirect_to customer_shop_success_path(booking_id: @booking.booking_number)
          else
            flash[:error] = 'Please add items to your cart before placing the order.'
            redirect_to customer_shop_path
          end
        end
      else
        flash[:error] = 'No items found in your cart. Please add items before placing an order.'
        redirect_to customer_shop_path
      end

    rescue ActiveRecord::RecordInvalid => e
      # Handle validation errors
      flash[:error] = "Order could not be placed: #{e.record.errors.full_messages.join(', ')}"
      redirect_to customer_shop_path

    rescue StandardError => e
      # Handle any other errors
      Rails.logger.error "Checkout Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:error] = 'An error occurred while processing your order. Please try again.'
      redirect_to customer_shop_path
    end
  end

  private

  def booking_params
    params.require(:booking).permit(
      :customer_name, :customer_email, :customer_phone,
      :delivery_address, :notes, :payment_method,
      :booking_date, :discount_amount
    )
  end
end