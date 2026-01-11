class Admin::BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking, only: [:show, :edit, :update, :destroy, :generate_invoice, :invoice, :convert_to_order, :update_status, :cancel_order, :mark_delivered, :mark_completed]

  def index
    # Start with base query for statistics (before filtering)
    @all_bookings = Booking.includes(:customer, :user, :booking_items, :order)

    # Apply filters
    @bookings = @all_bookings.recent

    if params[:search].present?
      @bookings = @bookings.where(
        "booking_number LIKE ? OR customer_name LIKE ? OR customer_email LIKE ? OR customer_phone LIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end

    if params[:status].present? && params[:status].strip != ''
      @bookings = @bookings.where(status: params[:status])
    end

    if params[:date_from].present? && params[:date_to].present?
      @bookings = @bookings.where(created_at: params[:date_from]..params[:date_to])
    end

    # Get pagination settings from system settings
    @per_page = SystemSetting.default_pagination_per_page

    # Paginate the filtered results
    @bookings = @bookings.page(params[:page]).per(@per_page)

    # Use all_bookings for statistics cards to show complete picture
    @bookings_for_stats = @all_bookings
  end

  def new
    @booking = Booking.new
    @booking.booking_items.build
    @products = Product.active.includes(:category, images_attachments: :blob)
    @customers = Customer.all.order(:first_name, :last_name)
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.user = current_user
    @booking.booking_date = Time.current
    # Remove the automatic status setting since it's now selected by the user
    # @booking.status = :ordered_and_delivery_pending
    @booking.payment_status = params[:booking][:payment_method] == 'cash' ? :paid : :unpaid

    if @booking.save
      # Calculate totals after saving
      @booking.calculate_totals
      @booking.save

      # Automatically generate invoice for all bookings
      @booking.generate_invoice_number

      Rails.logger.info "Booking ##{@booking.id} created with invoice ##{@booking.invoice_number}"

      # Convert to order if payment is received
      if @booking.payment_status_paid? && params[:create_order] == '1'
        @booking.convert_to_order!
      end

      redirect_to admin_booking_path(@booking), notice: 'Booking created successfully! Invoice generated.'
    else
      @products = Product.active.includes(:category, images_attachments: :blob)
      @customers = Customer.all.order(:first_name, :last_name)
      render :new
    end
  end

  def show
    @booking_items = @booking.booking_items.includes(product: [:category, images_attachments: :blob])
  end

  def edit
    @products = Product.active.includes(:category, images_attachments: :blob)
    @customers = Customer.all.order(:first_name, :last_name)
  end

  def update
    if @booking.update(booking_params)
      redirect_to admin_booking_path(@booking), notice: 'Booking updated successfully!'
    else
      @products = Product.active.includes(:category, images_attachments: :blob)
      @customers = Customer.all.order(:first_name, :last_name)
      render :edit
    end
  end

  def destroy
    if @booking.order.present?
      redirect_to admin_bookings_path, alert: 'Cannot delete booking with associated order.'
    else
      @booking.destroy
      redirect_to admin_bookings_path, notice: 'Booking deleted successfully!'
    end
  end

  def generate_invoice
    @booking.generate_invoice_number
    redirect_to invoice_admin_booking_path(@booking)
  end

  def invoice
    respond_to do |format|
      format.html { render template: 'admin/bookings/invoice_new', layout: 'invoice' }
      format.pdf do
        pdf = WickedPdf.new.pdf_from_string(
          render_to_string('admin/bookings/invoice', layout: 'invoice_pdf'),
          page_size: 'A4',
          margin: {
            top: '0.75in',
            bottom: '0.75in',
            left: '0.75in',
            right: '0.75in'
          },
          dpi: 300,
          encoding: 'UTF-8',
          disable_smart_shrinking: true,
          print_media_type: true,
          orientation: 'Portrait',
          header: {
            html: {
              template: 'shared/pdf_header'
            }
          },
          footer: {
            html: {
              template: 'shared/pdf_footer'
            }
          }
        )

        invoice_filename = "invoice-#{@booking.invoice_number || @booking.booking_number}-#{Date.current.strftime('%Y%m%d')}.pdf"

        send_data pdf,
                  filename: invoice_filename,
                  type: 'application/pdf',
                  disposition: 'attachment'
      end
    end
  end

  def convert_to_order
    if @booking.order.present?
      redirect_to admin_order_path(@booking.order), notice: 'Order already exists for this booking.'
    else
      order = @booking.convert_to_order!
      redirect_to admin_order_path(order), notice: 'Order created successfully!'
    end
  end

  # Status management actions
  def update_status
    new_status = params[:status]

    if @booking.next_possible_statuses.include?(new_status)
      case new_status
      when 'ordered_and_delivery_pending'
        @booking.update!(status: :ordered_and_delivery_pending)
        message = 'Booking moved to Ordered & Delivery Pending!'
      when 'confirmed'
        @booking.mark_as_confirmed!
        message = 'Booking confirmed successfully!'
      when 'processing'
        @booking.mark_as_processing!
        message = 'Order marked as processing!'
      when 'packed'
        @booking.mark_as_packed!
        message = 'Order packed successfully!'
      when 'shipped'
        @booking.mark_as_shipped!(params[:tracking_number])
        message = 'Order shipped successfully!'
      when 'out_for_delivery'
        @booking.mark_as_out_for_delivery!
        message = 'Order is out for delivery!'
      when 'delivered'
        @booking.mark_as_delivered!
        message = 'Order delivered and completed successfully!'
      when 'completed'
        @booking.mark_as_completed!
        message = 'Order completed!'
      else
        @booking.update!(status: new_status)
        message = "Status updated to #{new_status.humanize}!"
      end

      respond_to do |format|
        format.html { redirect_to admin_booking_path(@booking), notice: message }
        format.json { render json: { success: true, message: message, new_status: @booking.status } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_booking_path(@booking), alert: 'Invalid status transition!' }
        format.json { render json: { success: false, error: 'Invalid status transition!' } }
      end
    end
  end

  def cancel_order
    reason = params[:reason]
    @booking.cancel_order!(reason)
    redirect_to admin_booking_path(@booking), notice: 'Booking cancelled successfully!'
  end

  def mark_delivered
    @booking.mark_as_delivered!
    redirect_to admin_booking_path(@booking), notice: 'Order marked as delivered!'
  end

  def mark_completed
    @booking.mark_as_completed!
    redirect_to admin_booking_path(@booking), notice: 'Order marked as completed!'
  end

  # Real-time data endpoint
  def realtime_data
    # Get fresh data for statistics
    all_bookings = Booking.includes(:customer, :user, :booking_items, :order)

    stats = {
      draft: all_bookings.draft.count,
      pending: all_bookings.ordered_and_delivery_pending.count,
      processing: all_bookings.where(status: [:confirmed, :processing, :packed]).count,
      shipped: all_bookings.where(status: [:shipped, :out_for_delivery]).count,
      delivered: all_bookings.where(status: [:delivered, :completed]).count,
      issues: all_bookings.where(status: [:cancelled, :returned]).count,
      total: all_bookings.count,
      today_bookings: all_bookings.where(created_at: Date.current.all_day).count,
      total_revenue: all_bookings.where(status: [:completed, :delivered]).sum(:total_amount),
      last_updated: Time.current.strftime('%I:%M:%S %p')
    }

    # Get recent bookings (last 5)
    recent_bookings = all_bookings.recent.limit(5).includes(:customer, :booking_items).map do |booking|
      {
        id: booking.id,
        booking_number: booking.booking_number,
        customer_name: booking.customer&.display_name || booking.customer_name,
        status: booking.status,
        status_color: booking.status_color,
        status_icon: booking.status_icon,
        total_amount: booking.total_amount,
        created_at: booking.created_at.strftime('%d %b %Y %I:%M %p'),
        items_count: booking.booking_items.count
      }
    end

    render json: {
      success: true,
      stats: stats,
      recent_bookings: recent_bookings
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }
  end

  # AJAX endpoints
  def search_products
    @products = Product.active
                       .where("name ILIKE ? OR sku ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
                       .limit(10)

    render json: @products.map { |p|
      {
        id: p.id,
        text: "#{p.name} - #{p.formatted_selling_price}",
        name: p.name,
        price: p.selling_price,
        stock: p.stock,
        image_url: p.main_image ? url_for(p.main_image) : nil
      }
    }
  end

  def search_customers
    @customers = Customer.where(
      "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR mobile ILIKE ?",
      "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"
    ).limit(10)

    render json: @customers.map { |c|
      {
        id: c.id,
        text: "#{c.display_name} - #{c.mobile}",
        name: c.display_name,
        email: c.email,
        phone: c.mobile,
        address: c.address
      }
    }
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(
      :customer_id, :customer_name, :customer_email, :customer_phone,
      :payment_method, :payment_status, :discount_amount, :notes,
      :delivery_address, :cash_received, :change_amount, :status,
      booking_items_attributes: [:id, :product_id, :quantity, :price, :_destroy]
    )
  end
end