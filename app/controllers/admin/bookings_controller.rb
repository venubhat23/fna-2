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

  def stage_transition
    @target_stage = params[:target_stage]

    unless @target_stage.present?
      redirect_to admin_booking_path(@booking), alert: 'Target stage not specified'
      return
    end

    unless @booking.next_possible_statuses.include?(@target_stage) ||
           (@booking.can_return? && @target_stage == 'returned')
      redirect_to admin_booking_path(@booking), alert: 'Invalid stage transition'
      return
    end

    # Load delivery people for shipped stage
    @delivery_people = DeliveryPerson.where(status: true).order(:first_name, :last_name) if @target_stage == 'shipped'
  end

  def process_stage_transition
    @target_stage = params[:booking][:target_stage]

    unless @target_stage.present?
      redirect_to admin_booking_path(@booking), alert: 'Target stage not specified'
      return
    end

    case @target_stage
    when 'confirmed'
      process_confirmed_transition
    when 'processing'
      process_processing_transition
    when 'packed'
      process_packed_transition
    when 'shipped'
      process_shipped_transition
    when 'out_for_delivery'
      process_out_for_delivery_transition
    when 'delivered'
      process_delivered_transition
    when 'cancelled'
      process_cancelled_transition
    when 'returned'
      process_returned_transition
    else
      process_general_transition
    end
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

  # Stage transition processing methods
  def process_confirmed_transition
    notes_addition = params[:booking][:notes].present? ?
      "\nConfirmation Notes: #{params[:booking][:notes]}" : ""

    @booking.update!(
      status: :confirmed,
      notes: "#{@booking.notes}#{notes_addition}\nConfirmed at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: 'Booking confirmed successfully!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'confirmed'),
                alert: "Error confirming booking: #{e.message}"
  end

  def process_processing_transition
    processing_notes = params[:booking][:processing_notes] || ""
    estimated_completion = params[:booking][:estimated_completion]

    notes_addition = "\nProcessing Notes: #{processing_notes}" if processing_notes.present?
    notes_addition += "\nEstimated Completion: #{estimated_completion}" if estimated_completion.present?

    @booking.update!(
      status: :processing,
      notes: "#{@booking.notes}#{notes_addition}\nProcessing started at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: 'Booking moved to processing!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'processing'),
                alert: "Error processing booking: #{e.message}"
  end

  def process_packed_transition
    packaging_notes = params[:booking][:packaging_notes] || ""
    package_weight = params[:booking][:package_weight]
    package_dimensions = params[:booking][:package_dimensions]

    notes_addition = ""
    notes_addition += "\nPackaging Notes: #{packaging_notes}" if packaging_notes.present?
    notes_addition += "\nPackage Weight: #{package_weight}kg" if package_weight.present?
    notes_addition += "\nDimensions: #{package_dimensions}" if package_dimensions.present?

    @booking.update!(
      status: :packed,
      notes: "#{@booking.notes}#{notes_addition}\nPacked at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: 'Booking marked as packed!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'packed'),
                alert: "Error packing booking: #{e.message}"
  end

  def process_shipped_transition
    shipping_partner = params[:booking][:shipping_partner]
    partner_id = params[:booking][:partner_id]
    tracking_number = params[:booking][:tracking_number]
    delivery_person_id = params[:booking][:delivery_person_id]
    expected_delivery_date = params[:booking][:expected_delivery_date]
    shipping_instructions = params[:booking][:shipping_instructions] || ""

    unless shipping_partner.present? && tracking_number.present?
      redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'shipped'),
                  alert: 'Shipping partner and tracking number are required'
      return
    end

    delivery_person_info = ""
    if delivery_person_id.present?
      delivery_person = DeliveryPerson.find_by(id: delivery_person_id)
      delivery_person_info = "\nDelivery Person: #{delivery_person.first_name} #{delivery_person.last_name} (#{delivery_person.mobile})" if delivery_person
    end

    notes_addition = "\nShipping Partner: #{shipping_partner.humanize}"
    notes_addition += "\nPartner ID: #{partner_id}" if partner_id.present?
    notes_addition += "\nTracking Number: #{tracking_number}"
    notes_addition += delivery_person_info
    notes_addition += "\nExpected Delivery: #{expected_delivery_date}" if expected_delivery_date.present?
    notes_addition += "\nShipping Instructions: #{shipping_instructions}" if shipping_instructions.present?

    @booking.update!(
      status: :shipped,
      notes: "#{@booking.notes}#{notes_addition}\nShipped at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: 'Booking marked as shipped with tracking details!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'shipped'),
                alert: "Error shipping booking: #{e.message}"
  end

  def process_out_for_delivery_transition
    delivery_notes = params[:booking][:delivery_notes] || ""

    notes_addition = "\nDelivery Notes: #{delivery_notes}" if delivery_notes.present?

    @booking.update!(
      status: :out_for_delivery,
      notes: "#{@booking.notes}#{notes_addition}\nOut for delivery at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: 'Booking marked as out for delivery!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'out_for_delivery'),
                alert: "Error updating delivery status: #{e.message}"
  end

  def process_delivered_transition
    delivery_date = params[:booking][:delivery_date] || Time.current
    delivered_to = params[:booking][:delivered_to] || ""
    delivery_confirmation_notes = params[:booking][:delivery_confirmation_notes] || ""

    notes_addition = "\nDelivered to: #{delivered_to}" if delivered_to.present?
    notes_addition += "\nDelivery Confirmation: #{delivery_confirmation_notes}" if delivery_confirmation_notes.present?
    notes_addition += "\nDelivered at: #{delivery_date}"

    @booking.update!(
      status: :delivered,
      notes: "#{@booking.notes}#{notes_addition}"
    )

    # Auto-transition to completed as per original logic
    @booking.mark_as_completed!

    redirect_to admin_bookings_path, notice: 'Booking marked as delivered and completed!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'delivered'),
                alert: "Error marking as delivered: #{e.message}"
  end

  def process_cancelled_transition
    cancellation_reason = params[:booking][:cancellation_reason]
    cancellation_notes = params[:booking][:cancellation_notes]

    unless cancellation_reason.present? && cancellation_notes.present?
      redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'cancelled'),
                  alert: 'Cancellation reason and notes are required'
      return
    end

    cancel_reason_text = cancellation_reason.humanize
    notes_addition = "\nCancellation Reason: #{cancel_reason_text}"
    notes_addition += "\nCancellation Details: #{cancellation_notes}"

    @booking.update!(
      status: :cancelled,
      notes: "#{@booking.notes}#{notes_addition}\nCancelled at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: 'Booking cancelled successfully!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'cancelled'),
                alert: "Error cancelling booking: #{e.message}"
  end

  def process_returned_transition
    return_reason = params[:booking][:return_reason]
    return_notes = params[:booking][:return_notes]

    unless return_reason.present? && return_notes.present?
      redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'returned'),
                  alert: 'Return reason and notes are required'
      return
    end

    return_reason_text = return_reason.humanize
    notes_addition = "\nReturn Reason: #{return_reason_text}"
    notes_addition += "\nReturn Details: #{return_notes}"

    @booking.update!(
      status: :returned,
      notes: "#{@booking.notes}#{notes_addition}\nReturned at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: 'Return processed successfully!'
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: 'returned'),
                alert: "Error processing return: #{e.message}"
  end

  def process_general_transition
    general_notes = params[:booking][:general_notes] || ""

    notes_addition = "\nUpdate Notes: #{general_notes}" if general_notes.present?

    @booking.update!(
      status: @target_stage,
      notes: "#{@booking.notes}#{notes_addition}\nUpdated to #{@target_stage.humanize} at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
    )

    redirect_to admin_bookings_path, notice: "Booking updated to #{@target_stage.humanize}!"
  rescue => e
    redirect_to stage_transition_admin_booking_path(@booking, target_stage: @target_stage),
                alert: "Error updating booking: #{e.message}"
  end
end