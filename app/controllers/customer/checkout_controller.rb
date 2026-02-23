class Customer::CheckoutController < Customer::BaseController
  before_action :initialize_cart
  before_action :check_cart_not_empty, except: [:confirmation]

  def show
    @cart_items = @cart[:items] || []
    @cart_total = calculate_cart_total
    @addresses = current_customer.customer_addresses || []
  end

  def address
    @addresses = current_customer.customer_addresses || []
    @new_address = CustomerAddress.new
  end

  def create_address
    @new_address = current_customer.customer_addresses.build(address_params)

    if @new_address.save
      redirect_to customer_checkout_payment_path, notice: 'Address added successfully!'
    else
      @addresses = current_customer.customer_addresses
      render :address
    end
  end

  def payment
    @cart_items = @cart[:items] || []
    @cart_total = calculate_cart_total
    @selected_address = find_selected_address

    if @selected_address.nil?
      redirect_to customer_checkout_address_path, alert: 'Please select a delivery address.'
      return
    end
  end

  def create
    @selected_address = find_selected_address

    if @selected_address.nil?
      redirect_to customer_checkout_address_path, alert: 'Please select a delivery address.'
      return
    end

    # Create booking/order
    ActiveRecord::Base.transaction do
      @booking = create_booking
      @order = create_order_from_booking

      if @booking.persisted? && @order.persisted?
        # Clear cart
        session[:cart] = { items: [] }
        redirect_to customer_checkout_confirmation_path(order_id: @order.id)
      else
        raise ActiveRecord::Rollback
      end
    end

  rescue ActiveRecord::Rollback
    @cart_items = @cart[:items] || []
    @cart_total = calculate_cart_total
    flash.now[:alert] = 'Failed to process order. Please try again.'
    render :payment
  end

  def confirmation
    @order = current_customer.orders.find(params[:order_id])
    @order_items = JSON.parse(@order.order_items || '[]')
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_orders_path, alert: 'Order not found.'
  end

  private

  def initialize_cart
    @cart = session[:cart] ||= { items: [] }
  end

  def check_cart_not_empty
    if @cart[:items].blank?
      redirect_to customer_products_path, alert: 'Your cart is empty.'
    end
  end

  def calculate_cart_total
    @cart[:items].sum { |item| item['price'].to_f * item['quantity'].to_i }
  end

  def find_selected_address
    address_id = params[:selected_address_id] || session[:selected_address_id]
    return nil if address_id.blank?

    current_customer.customer_addresses.find_by(id: address_id)
  end

  def create_booking
    cart_items = @cart[:items].map do |item|
      product = Product.find(item['product_id'])
      {
        product_id: product.id,
        product_name: product.name,
        quantity: item['quantity'],
        price: product.selling_price,
        total: product.selling_price * item['quantity']
      }
    end

    booking = current_customer.bookings.build(
      booking_number: generate_booking_number,
      booking_date: Time.current,
      status: 'pending',
      payment_method: params[:payment_method] || 'cod',
      payment_status: 'pending',
      subtotal: calculate_cart_total,
      total_amount: calculate_cart_total,
      booking_items: cart_items.to_json,
      customer_name: current_customer.full_name,
      customer_email: current_customer.email,
      customer_phone: current_customer.mobile,
      delivery_address: format_delivery_address
    )

    booking.save!
    booking
  end

  def create_order_from_booking
    order_items = JSON.parse(@booking.booking_items || '[]')

    order = current_customer.orders.build(
      booking_id: @booking.id,
      order_number: generate_order_number,
      order_date: Time.current,
      status: 'pending',
      payment_method: @booking.payment_method,
      payment_status: @booking.payment_status,
      subtotal: @booking.subtotal,
      total_amount: @booking.total_amount,
      order_items: @booking.booking_items,
      customer_name: @booking.customer_name,
      customer_email: @booking.customer_email,
      customer_phone: @booking.customer_phone,
      delivery_address: @booking.delivery_address
    )

    order.save!
    order
  end

  def generate_booking_number
    "BK#{Date.current.strftime('%Y%m%d')}#{rand(1000..9999)}"
  end

  def generate_order_number
    "ORD#{Date.current.strftime('%Y%m%d')}#{rand(1000..9999)}"
  end

  def format_delivery_address
    return '' unless @selected_address

    "#{@selected_address.name}\n#{@selected_address.address}\n#{@selected_address.landmark}\n#{@selected_address.city}, #{@selected_address.state} - #{@selected_address.pincode}\nMobile: #{@selected_address.mobile}"
  end

  def address_params
    params.require(:customer_address).permit(
      :name, :mobile, :address_type, :address, :landmark,
      :city, :state, :pincode, :is_default
    )
  end
end