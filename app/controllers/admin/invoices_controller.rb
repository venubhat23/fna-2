require 'set'

class Admin::InvoicesController < Admin::ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :mark_as_paid]

  def index
    invoice_type = params[:type] || 'regular'
    per_page = SystemSetting.default_pagination_per_page
    page = (params[:page] || 1).to_i

    # Fetch all regular invoices (no pagination yet)
    all_regular = build_regular_invoices_query.map { |inv| prepare_invoice_data(inv, 'regular') }

    # Fetch booking-only invoices
    all_booking = build_booking_only_invoices_query.map { |b| prepare_booking_invoice_data(b) }

    # Combine and sort by created_at descending (newest first)
    combined = (all_regular + all_booking).sort_by { |inv| inv[:created_at] || Time.at(0) }.reverse

    # Manual pagination
    total = combined.size
    offset = (page - 1) * per_page
    @invoices = combined[offset, per_page] || []

    # Build a simple pagination wrapper for view helpers
    @paginated_invoices = Kaminari.paginate_array(combined).page(page).per(per_page)

    @stats = calculate_regular_invoice_stats_only
    @delivery_persons = DeliveryPerson.active.order(:first_name, :last_name)
    @invoice_type = invoice_type
  end

  def customers
    # Handle search term for filtering
    customers_query = Customer.active.order(:first_name, :last_name)
                             .select(:id, :first_name, :middle_name, :last_name, :email, :mobile)

    # Apply search filter if term is provided
    if params[:term].present?
      search_term = "%#{params[:term]}%"
      customers_query = customers_query.where(
        "CONCAT(customers.first_name, ' ', customers.last_name) ILIKE ? OR
         CONCAT(customers.first_name, ' ', COALESCE(customers.middle_name, ''), ' ', customers.last_name) ILIKE ? OR
         customers.first_name ILIKE ? OR
         customers.last_name ILIKE ? OR
         customers.email ILIKE ? OR
         customers.mobile ILIKE ?",
        search_term, search_term, search_term, search_term, search_term, search_term
      )
    end

    @customers = customers_query.limit(50).map do |c|
      {
        id: c.id,
        display_name: c.display_name,
        email: c.email,
        mobile: c.mobile
      }
    end

    render json: @customers
  end

  def delivery_persons
    @delivery_persons = DeliveryPerson.active.order(:first_name, :last_name)
                                     .select(:id, :first_name, :last_name)
                                     .map { |dp| { id: dp.id, display_name: dp.display_name } }
    render json: @delivery_persons
  end

  def customers_by_delivery_person
    delivery_person_id = params[:delivery_person_id]
    if delivery_person_id.present?
      # Find customers who have bookings with this delivery person
      booking_customer_ids = Booking.where(delivery_person_id: delivery_person_id)
                                   .distinct
                                   .pluck(:customer_id)
                                   .compact

      # Find customers who have subscriptions with this delivery person
      subscription_customer_ids = []
      if defined?(MilkSubscription)
        subscription_customer_ids += MilkSubscription.where(delivery_person_id: delivery_person_id)
                                                    .distinct
                                                    .pluck(:customer_id)
                                                    .compact
      end

      if defined?(SubscriptionTemplate)
        subscription_customer_ids += SubscriptionTemplate.where(delivery_person_id: delivery_person_id)
                                                         .distinct
                                                         .pluck(:customer_id)
                                                         .compact
      end

      # Combine all customer IDs from bookings and subscriptions
      all_customer_ids = (booking_customer_ids + subscription_customer_ids).uniq

      @customers = Customer.where(id: all_customer_ids)
                          .order(:first_name, :last_name)
                          .select(:id, :first_name, :middle_name, :last_name, :email, :mobile)
                          .map { |c| {
                            id: c.id,
                            display_name: c.display_name,
                            email: c.email,
                            mobile: c.mobile
                          } }
    else
      @customers = []
    end
    render json: @customers
  end

  def available_customers
    month = params[:month].to_i
    year = params[:year].to_i
    customer_selection = params[:customer_selection]
    delivery_person_id = params[:delivery_person_id]

    # Get potential customers
    potential_customers = case customer_selection
    when 'all'
      Customer.active.order(:first_name, :last_name)
    when 'delivery_person'
      if delivery_person_id.present?
        # Get customers from bookings and subscriptions for delivery person
        booking_customer_ids = Booking.where(delivery_person_id: delivery_person_id)
                                     .distinct.pluck(:customer_id).compact.uniq
        subscription_customer_ids = []
        subscription_customer_ids += MilkSubscription.where(delivery_person_id: delivery_person_id)
                                                    .distinct.pluck(:customer_id).compact if defined?(MilkSubscription)
        subscription_customer_ids += SubscriptionTemplate.where(delivery_person_id: delivery_person_id)
                                                         .distinct.pluck(:customer_id).compact if defined?(SubscriptionTemplate)

        all_customer_ids = (booking_customer_ids + subscription_customer_ids).uniq
        Customer.where(id: all_customer_ids).order(:first_name, :last_name)
      else
        Customer.none
      end
    else
      Customer.active.order(:first_name, :last_name)
    end

    # Filter customers based on invoice status and uninvoiced MilkDeliveryTasks
    if month > 0 && year > 0
      # Get customers who already have invoices for this month/year
      existing_customer_ids = Invoice.where(month: month, year: year)
                                    .where(customer_id: potential_customers.pluck(:id))
                                    .pluck(:customer_id)

      # Get customers who don't have invoices for this month
      customers_without_invoices = potential_customers.where.not(id: existing_customer_ids).pluck(:id)

      # Get customers who have uninvoiced MilkDeliveryTasks for this month
      customers_with_uninvoiced_tasks = []
      if defined?(MilkDeliveryTask)
        start_date = Date.new(year, month, 1)
        end_date = Date.new(year, month, -1)
        customers_with_uninvoiced_tasks = Customer.joins(:milk_delivery_tasks)
                                                 .where(id: potential_customers.pluck(:id))
                                                 .where(milk_delivery_tasks: {
                                                   delivery_date: start_date..end_date,
                                                   invoiced: [false, nil]
                                                 })
                                                 .distinct
                                                 .pluck(:id)
      end

      # Combine both groups: customers without invoices OR customers with uninvoiced tasks
      final_customer_ids = (customers_without_invoices + customers_with_uninvoiced_tasks).uniq
      available_customers = potential_customers.where(id: final_customer_ids)
    else
      available_customers = potential_customers
    end

    # Format response
    @customers = available_customers.limit(200).map do |c|
      {
        id: c.id,
        display_name: c.display_name,
        email: c.email,
        mobile: c.mobile
      }
    end

    render json: @customers
  end

  def invoice_generation_summary
    month = params[:month].to_i
    year = params[:year].to_i
    customer_selection = params[:customer_selection]
    customer_ids = params[:customer_ids]&.map(&:to_i)
    delivery_person_id = params[:delivery_person_id]

    # Get all potential customers based on selection
    potential_customers = get_potential_customers(customer_selection, customer_ids, delivery_person_id)

    # Find customers who already have invoices for this month/year
    existing_invoices = Invoice.where(month: month, year: year)
                              .where(customer_id: potential_customers.pluck(:id))
                              .includes(:customer)

    existing_customer_ids = existing_invoices.pluck(:customer_id)

    # Get customers who don't have invoices for this month
    customers_without_invoices = potential_customers.where.not(id: existing_customer_ids).pluck(:id)

    # Get customers who have uninvoiced MilkDeliveryTasks for this month
    customers_with_uninvoiced_tasks = []
    if defined?(MilkDeliveryTask)
      start_date = Date.new(year, month, 1)
      end_date = Date.new(year, month, -1)

      customers_with_uninvoiced_tasks = Customer.joins(:milk_delivery_tasks)
                                               .where(id: potential_customers.pluck(:id))
                                               .where(milk_delivery_tasks: {
                                                 delivery_date: start_date..end_date,
                                                 invoiced: [false, nil]
                                               })
                                               .distinct
                                               .pluck(:id)
    end

    # Combine both groups: customers without invoices OR customers with uninvoiced tasks
    final_customer_ids = (customers_without_invoices + customers_with_uninvoiced_tasks).uniq
    available_customers = potential_customers.where(id: final_customer_ids)

    summary = {
      month: month,
      year: year,
      month_name: Date::MONTHNAMES[month],
      total_potential_customers: potential_customers.count,
      existing_invoices_count: existing_invoices.count,
      available_customers_count: available_customers.count,
      customers_with_uninvoiced_tasks: customers_with_uninvoiced_tasks.count,
      existing_customers: existing_invoices.map { |inv|
        {
          id: inv.customer.id,
          name: inv.customer.display_name,
          invoice_number: inv.invoice_number,
          amount: inv.total_amount
        }
      },
      available_customers: available_customers.limit(10).map { |c|
        {
          id: c.id,
          name: c.display_name,
          mobile: c.mobile
        }
      }
    }

    render json: summary
  end

  def generate
    month = params[:month].to_i
    year = params[:year].to_i
    customer_selection = params[:customer_selection]
    customer_ids = params[:customer_ids]&.map(&:to_i)
    delivery_person_id = params[:delivery_person_id]

    # Get pending items summary before generation
    pending_summary = get_pending_items_summary(customer_selection, customer_ids, delivery_person_id)

    # Get potential customers using the helper method
    potential_customers = get_potential_customers(customer_selection, customer_ids, delivery_person_id)

    # Filter customers based on invoice status and uninvoiced MilkDeliveryTasks
    existing_customer_ids = Invoice.where(month: month, year: year)
                                  .where(customer_id: potential_customers.pluck(:id))
                                  .pluck(:customer_id)

    # Get customers who don't have invoices for this month
    customers_without_invoices = potential_customers.where.not(id: existing_customer_ids).pluck(:id)

    # Get customers who have uninvoiced MilkDeliveryTasks for this month
    customers_with_uninvoiced_tasks = []
    if defined?(MilkDeliveryTask)
      start_date = Date.new(year, month, 1)
      end_date = Date.new(year, month, -1)

      customers_with_uninvoiced_tasks = Customer.joins(:milk_delivery_tasks)
                                               .where(id: potential_customers.pluck(:id))
                                               .where(milk_delivery_tasks: {
                                                 delivery_date: start_date..end_date,
                                                 invoiced: [false, nil]
                                               })
                                               .distinct
                                               .pluck(:id)
    end

    # Combine both groups: customers without invoices OR customers with uninvoiced tasks
    final_customer_ids = (customers_without_invoices + customers_with_uninvoiced_tasks).uniq
    customers = potential_customers.where(id: final_customer_ids)
    customer_count = customers.count

    generated_invoices = []
    errors = []

    # Define batch size based on customer count
    batch_size = customer_count <= 5 ? customer_count : 10

    Rails.logger.info("Processing #{customer_count} customers in batches of #{batch_size}")

    if customer_count <= 5
      # For 5 or fewer customers, process in a single transaction
      Rails.logger.info("Processing #{customer_count} customers in single transaction")

      Invoice.transaction do
        customers.find_each do |customer|
          begin
            invoice = generate_customer_invoice(customer, month, year)
            generated_invoices << invoice if invoice
          rescue => e
            error_message = "#{customer.display_name}: #{e.message}"
            errors << error_message

            # If any customer fails, rollback the entire transaction
            Rails.logger.error("Invoice generation failed for customer #{customer.id}: #{e.message}")
            Rails.logger.error(e.backtrace.join("\n"))
            raise ActiveRecord::Rollback, "Failed to generate invoice for #{customer.display_name}: #{e.message}"
          end
        end

        Rails.logger.info("Successfully generated #{generated_invoices.count} invoices in single transaction")
      end
    else
      # For more than 5 customers, process in batches with individual transactions
      Rails.logger.info("Processing #{customer_count} customers in batches of #{batch_size}")

      batch_number = 0
      successful_batches = 0
      failed_batches = 0

      customers.in_batches(of: batch_size) do |batch|
        batch_number += 1
        batch_customers = batch.to_a
        batch_generated = []
        batch_errors = []

        Rails.logger.info("Processing batch #{batch_number} with #{batch_customers.count} customers")

        # Process each batch in its own transaction
        Invoice.transaction do
          batch_customers.each do |customer|
            begin
              invoice = generate_customer_invoice(customer, month, year)
              batch_generated << invoice if invoice
            rescue => e
              error_message = "#{customer.display_name}: #{e.message}"
              batch_errors << error_message

              Rails.logger.error("Invoice generation failed for customer #{customer.id} in batch #{batch_number}: #{e.message}")
              raise ActiveRecord::Rollback, "Failed to generate invoice for #{customer.display_name} in batch #{batch_number}: #{e.message}"
            end
          end

          # If we reach here, the entire batch succeeded
          Rails.logger.info("Batch #{batch_number} completed successfully with #{batch_generated.count} invoices")
          successful_batches += 1
        end

        # Add batch results to overall results (only if batch transaction succeeded)
        if batch_errors.empty?
          generated_invoices.concat(batch_generated)
        else
          failed_batches += 1
          errors.concat(batch_errors)
          Rails.logger.error("Batch #{batch_number} failed and was rolled back")
        end
      end

      Rails.logger.info("Batch processing completed: #{successful_batches} successful batches, #{failed_batches} failed batches")
    end

    # Determine processing type for response message
    processing_type = customer_count <= 5 ? "single transaction" : "#{batch_size}-customer batches"

    # Generate response based on results
    if generated_invoices.any?
      success_rate = (generated_invoices.count.to_f / customer_count * 100).round(1)

      if errors.empty?
        # All invoices generated successfully
        render json: {
          success: true,
          invoices_created: generated_invoices.count,
          total_customers: customer_count,
          success_rate: success_rate,
          processing_type: processing_type,
          message: customer_count <= 5 ?
            "Successfully generated #{generated_invoices.count} invoices in a single transaction" :
            "Successfully generated #{generated_invoices.count}/#{customer_count} invoices using batch processing (#{success_rate}% success rate)",
          batch_info: customer_count > 5 ? {
            batch_size: batch_size,
            successful_batches: successful_batches,
            failed_batches: failed_batches,
            total_batches: successful_batches + failed_batches
          } : nil,
          errors: [],
          pending_items_summary: pending_summary,
          invoices: generated_invoices.map { |inv| {
            id: inv.id,
            number: inv.invoice_number,
            customer: inv.customer.display_name,
            amount: inv.total_amount
          } }
        }
      else
        # Some invoices generated, some failed (batch mode only)
        render json: {
          success: true,
          invoices_created: generated_invoices.count,
          total_customers: customer_count,
          success_rate: success_rate,
          processing_type: processing_type,
          message: "Partially successful: Generated #{generated_invoices.count}/#{customer_count} invoices using batch processing. Some batches failed.",
          batch_info: {
            batch_size: batch_size,
            successful_batches: successful_batches,
            failed_batches: failed_batches,
            total_batches: successful_batches + failed_batches
          },
          warnings: errors,
          pending_items_summary: pending_summary,
          invoices: generated_invoices.map { |inv| {
            id: inv.id,
            number: inv.invoice_number,
            customer: inv.customer.display_name,
            amount: inv.total_amount
          } }
        }
      end
    elsif errors.any?
      # Complete failure
      render json: {
        success: false,
        invoices_created: 0,
        total_customers: customer_count,
        processing_type: processing_type,
        error: customer_count <= 5 ?
          "Invoice generation failed. Transaction was rolled back to maintain data integrity." :
          "All batches failed during invoice generation. No invoices were created.",
        detailed_errors: errors,
        message: customer_count <= 5 ?
          "All or nothing approach: No invoices were created because one or more customers had errors." :
          "Batch processing failed: All #{batch_size}-customer batches encountered errors and were rolled back.",
        batch_info: customer_count > 5 ? {
          batch_size: batch_size,
          successful_batches: successful_batches,
          failed_batches: failed_batches,
          total_batches: successful_batches + failed_batches
        } : nil,
        pending_items_summary: pending_summary
      }
    else
      # No customers to process
      render json: {
        success: false,
        invoices_created: 0,
        total_customers: 0,
        error: "No customers available for invoice generation.",
        message: "All selected customers already have invoices for this period or no completed deliveries found.",
        pending_items_summary: pending_summary
      }
    end
  end

  def show
    @invoice_items = @invoice&.invoice_items&.includes(:product, :milk_delivery_task) || []
  end

  def edit
    @invoice_items = @invoice.invoice_items.includes(:product, :milk_delivery_task)
  end

  def update
    # Store original quantities for stock rollback if needed
    original_quantities = {}
    @invoice.invoice_items.each do |item|
      original_quantities[item.id] = item.quantity if item.product
    end

    @invoice.assign_attributes(invoice_params)

    # Calculate new total based on invoice items and check stock availability
    new_total = 0
    stock_errors = []

    # Check nested attributes from params
    invoice_items_attributes = invoice_params[:invoice_items_attributes]

    if invoice_items_attributes
      invoice_items_attributes.each do |_, item_attrs|
        next if item_attrs['_destroy'] == '1'

        quantity = item_attrs['quantity'].to_f
        unit_price = item_attrs['unit_price'].to_f
        new_total += quantity * unit_price

        # Check stock availability for products
        if item_attrs['product_id'].present?
          product = Product.find(item_attrs['product_id'])
          item_id = item_attrs['id']

          # Calculate quantity difference
          # For new items (no ID), original_qty is 0
          original_qty = item_id.present? ? (original_quantities[item_id.to_i] || 0) : 0
          qty_difference = quantity - original_qty

          # Only check stock if quantity is increasing and product tracks stock
          if qty_difference > 0 && product.respond_to?(:track_stock?) && product.track_stock?
            if product.respond_to?(:available_stock)
              available_stock = product.available_stock
              if available_stock < qty_difference
                stock_errors << "Insufficient stock for #{product.name}. Available: #{available_stock}, Required additional: #{qty_difference}"
              end
            end
          end
        end
      end
    end

    # If there are stock errors, don't save and show errors
    unless stock_errors.empty?
      @invoice.errors.add(:base, stock_errors.join(', '))
      @invoice_items = @invoice.invoice_items.includes(:product, :milk_delivery_task)
      render :edit, status: :unprocessable_entity
      return
    end

    @invoice.total_amount = new_total

    if @invoice.save
      # Update stock for products after successful save
      @invoice.invoice_items.each do |item|
        if item.product && item.product.respond_to?(:track_stock?) && item.product.track_stock?
          # For new items, original_quantities won't have this item.id, so original_qty = 0
          original_qty = original_quantities[item.id] || 0
          qty_difference = item.quantity - original_qty

          # Only update stock if there's a quantity change and product supports stock updates
          if qty_difference != 0 && item.product.respond_to?(:update_stock_for_invoice)
            item.product.update_stock_for_invoice(qty_difference)
          end
        end
      end

      # Update related booking stock if invoice is connected to a booking
      update_related_booking_stock(original_quantities)

      redirect_to admin_invoice_path(@invoice), notice: 'Invoice was successfully updated.'
    else
      @invoice_items = @invoice.invoice_items.includes(:product, :milk_delivery_task)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to admin_invoices_path, notice: 'Invoice was successfully deleted.'
  rescue => e
    redirect_to admin_invoices_path, alert: "Error deleting invoice: #{e.message}"
  end

  def mark_as_paid
    @invoice.update!(
      payment_status: :fully_paid,
      status: :paid,
      paid_at: Time.current
    )

    redirect_to admin_invoices_path, notice: 'Invoice marked as paid successfully.'
  rescue => e
    redirect_to admin_invoices_path, alert: "Error marking invoice as paid: #{e.message}"
  end

  def bulk_mark_as_paid
    invoice_ids = params[:invoice_ids]

    if invoice_ids.blank? || !invoice_ids.is_a?(Array)
      render json: { success: false, error: 'No invoice IDs provided' }, status: :bad_request
      return
    end

    # Find invoices that are not already paid
    invoices_to_update = Invoice.where(id: invoice_ids)
                               .where.not(payment_status: 'fully_paid')

    if invoices_to_update.empty?
      render json: { success: false, error: 'No unpaid invoices found to update' }, status: :bad_request
      return
    end

    updated_count = 0

    Invoice.transaction do
      invoices_to_update.find_each do |invoice|
        invoice.update!(
          payment_status: :fully_paid,
          status: :paid,
          paid_at: Time.current
        )
        updated_count += 1
      end
    end

    render json: {
      success: true,
      updated_count: updated_count,
      message: "Successfully marked #{updated_count} invoice(s) as paid"
    }
  rescue => e
    Rails.logger.error "Bulk mark as paid error: #{e.message}"
    render json: {
      success: false,
      error: "Error marking invoices as paid: #{e.message}"
    }, status: :internal_server_error
  end

  def partial_payment
    begin
      invoice_id = params[:invoice_id]
      amount = params[:amount].to_f
      notes = params[:notes]

      if invoice_id.blank? || amount <= 0
        render json: { success: false, error: 'Invalid invoice ID or amount' }, status: :bad_request
        return
      end

      invoice = Invoice.find(invoice_id)

      # Get current paid amount (initialize if needed)
      current_paid_amount = invoice.paid_amount || 0
      new_paid_amount = current_paid_amount + amount

      # Calculate remaining amount
      remaining_amount = invoice.total_amount - new_paid_amount

      # Validate payment amount
      if new_paid_amount > invoice.total_amount
        render json: {
          success: false,
          error: 'Payment amount exceeds remaining invoice amount'
        }, status: :bad_request
        return
      end

      # Update invoice with payment information
      Invoice.transaction do
        # Update paid amount and payment status
        if remaining_amount <= 0
          invoice.update!(
            paid_amount: invoice.total_amount,
            payment_status: :fully_paid,
            status: :paid,
            paid_at: Time.current
          )
        else
          invoice.update!(
            paid_amount: new_paid_amount,
            payment_status: :partially_paid
          )
        end

        # Create a payment record/note if notes are provided
        if notes.present?
          # You can create a separate payment record here if needed
          # For now, we'll just update the invoice notes
          existing_notes = invoice.notes.present? ? invoice.notes : ""
          payment_note = "Payment of ₹#{amount} on #{Time.current.strftime('%Y-%m-%d %H:%M')} - #{notes}"

          if existing_notes.present?
            invoice.update!(notes: "#{existing_notes}\n#{payment_note}")
          else
            invoice.update!(notes: payment_note)
          end
        end
      end

      render json: {
        success: true,
        message: remaining_amount <= 0 ? 'Invoice marked as fully paid' : 'Partial payment processed successfully',
        invoice: {
          id: invoice.id,
          paid_amount: invoice.paid_amount,
          remaining_amount: invoice.total_amount - invoice.paid_amount,
          payment_status: invoice.payment_status
        }
      }

    rescue ActiveRecord::RecordNotFound
      render json: { success: false, error: 'Invoice not found' }, status: :not_found
    rescue => e
      Rails.logger.error "Partial payment error: #{e.message}"
      render json: {
        success: false,
        error: "Error processing partial payment: #{e.message}"
      }, status: :internal_server_error
    end
  end

  private

  def get_potential_customers(customer_selection, customer_ids, delivery_person_id)
    case customer_selection
    when 'all'
      Customer.active.distinct
    when 'delivery_person'
      if delivery_person_id.present?
        # Get customers from bookings
        booking_customer_ids = Booking.where(delivery_person_id: delivery_person_id)
                                     .distinct
                                     .pluck(:customer_id)
                                     .compact
                                     .uniq

        # Get customers from subscriptions
        subscription_customer_ids = []
        if defined?(MilkSubscription)
          subscription_customer_ids += MilkSubscription.where(delivery_person_id: delivery_person_id)
                                                      .distinct
                                                      .pluck(:customer_id)
                                                      .compact
        end

        if defined?(SubscriptionTemplate)
          subscription_customer_ids += SubscriptionTemplate.where(delivery_person_id: delivery_person_id)
                                                           .distinct
                                                           .pluck(:customer_id)
                                                           .compact
        end

        # Combine and ensure unique customer IDs
        all_customer_ids = (booking_customer_ids + subscription_customer_ids).uniq

        # If specific customers selected, use intersection
        if customer_ids.present?
          final_customer_ids = (all_customer_ids & customer_ids).uniq
          Customer.where(id: final_customer_ids).distinct
        else
          Customer.where(id: all_customer_ids).distinct
        end
      else
        Customer.none
      end
    else
      # Direct customer selection
      unique_customer_ids = customer_ids.present? ? customer_ids.uniq : []
      Customer.where(id: unique_customer_ids).distinct
    end
  end

  def build_booking_only_invoices_query
    invoiced_numbers = Invoice.pluck(:invoice_number).compact
    query = Booking.includes(:customer)
                   .where(invoice_generated: true)
                   .where.not(invoice_number: [nil, ''])
                   .where.not(invoice_number: invoiced_numbers)

    query = query.where(customer_id: params[:customer_id]) if params[:customer_id].present?

    if params[:search].present?
      s = "%#{params[:search]}%"
      query = query.joins(:customer)
                   .where("bookings.invoice_number ILIKE ? OR bookings.booking_number ILIKE ? OR customers.first_name ILIKE ? OR customers.last_name ILIKE ?", s, s, s, s)
    end

    query.order(created_at: :desc)
  end

  def prepare_booking_invoice_data(booking)
    {
      id: booking.id,
      invoice_number: booking.invoice_number,
      customer_name: booking.customer&.display_name || booking.customer_name || 'N/A',
      customer_mobile: booking.customer&.mobile || booking.customer_phone,
      total_amount: booking.total_amount,
      paid_amount: 0,
      payment_status: booking.payment_status || 'unpaid',
      status: 'draft',
      invoice_date: booking.booking_date&.to_date || booking.created_at&.to_date,
      created_at: booking.created_at,
      type: 'booking_only',
      model_object: booking,
      booking_number: booking.booking_number,
      from_booking: true
    }
  end

  def build_regular_invoices_query
    base_query = Invoice.includes(:customer, :invoice_items)
    apply_search_filters(base_query, 'invoices')
  end

  def build_booking_invoices_query
    base_query = BookingInvoice.includes(:customer, :booking)
    apply_search_filters(base_query, 'booking_invoices')
  end

  def build_regular_invoices_query_for_stats
    base_query = Invoice.includes(:customer)
    apply_search_filters_for_stats(base_query, 'invoices')
  end

  def build_booking_invoices_query_for_stats
    base_query = BookingInvoice.includes(:customer)
    apply_search_filters_for_stats(base_query, 'booking_invoices')
  end

  def apply_search_filters(base_query, table_name)
    # Apply search filters
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_query = base_query.joins(:customer)
                            .where("#{table_name}.invoice_number ILIKE ? OR
                                    customers.first_name ILIKE ? OR
                                    customers.last_name ILIKE ? OR
                                    customers.email ILIKE ? OR
                                    customers.mobile ILIKE ? OR
                                    CONCAT(customers.first_name, ' ', customers.last_name) ILIKE ? OR
                                    CONCAT(customers.first_name, ' ', COALESCE(customers.middle_name, ''), ' ', customers.last_name) ILIKE ?",
                                   search_term, search_term, search_term, search_term, search_term, search_term, search_term)
    end

    # Apply customer filter
    if params[:customer_id].present?
      base_query = base_query.where(customer_id: params[:customer_id])
    end

    # Apply delivery person filter based on milk subscriptions
    if params[:delivery_person_id].present? && params[:delivery_person_id] != 'all'
      delivery_person_id = params[:delivery_person_id].to_i

      # Get customers associated with this delivery person through milk subscriptions
      customer_ids_from_subscriptions = MilkSubscription.where(delivery_person_id: delivery_person_id)
                                                       .distinct
                                                       .pluck(:customer_id)
                                                       .compact

      # Also get customers from subscription templates
      customer_ids_from_templates = []
      if defined?(SubscriptionTemplate)
        customer_ids_from_templates = SubscriptionTemplate.where(delivery_person_id: delivery_person_id)
                                                         .distinct
                                                         .pluck(:customer_id)
                                                         .compact
      end

      # Combine all customer IDs from subscriptions
      all_customer_ids = (customer_ids_from_subscriptions + customer_ids_from_templates).uniq

      if all_customer_ids.any?
        base_query = base_query.where(customer_id: all_customer_ids)
      else
        # If no customers found for this delivery person, return empty result
        base_query = base_query.none
      end
    end

    # Apply status filter
    if params[:status].present? && params[:status] != 'all'
      if params[:status] == 'pending'
        base_query = base_query.where(payment_status: ['unpaid', 'partially_paid'])
      else
        base_query = base_query.where(payment_status: params[:status])
      end
    end

    # Apply date range filter
    if params[:date_from].present?
      date_column = table_name == 'invoices' ? 'invoice_date' : 'invoice_date'
      base_query = base_query.where("#{table_name}.#{date_column} >= ?", Date.parse(params[:date_from]))
    end

    if params[:date_to].present?
      date_column = table_name == 'invoices' ? 'invoice_date' : 'invoice_date'
      base_query = base_query.where("#{table_name}.#{date_column} <= ?", Date.parse(params[:date_to]))
    end

    base_query.order(created_at: :desc) # Pagination handled by Kaminari
  end

  def apply_search_filters_for_stats(base_query, table_name)
    # Apply same search filters as above but without the limit for accurate stats
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_query = base_query.joins(:customer)
                            .where("#{table_name}.invoice_number ILIKE ? OR
                                    customers.first_name ILIKE ? OR
                                    customers.last_name ILIKE ? OR
                                    customers.email ILIKE ? OR
                                    customers.mobile ILIKE ?",
                                   search_term, search_term, search_term, search_term, search_term)
    end

    # Apply delivery person filter based on milk subscriptions
    if params[:delivery_person_id].present? && params[:delivery_person_id] != 'all'
      delivery_person_id = params[:delivery_person_id].to_i

      # Get customers associated with this delivery person through milk subscriptions
      customer_ids_from_subscriptions = MilkSubscription.where(delivery_person_id: delivery_person_id)
                                                       .distinct
                                                       .pluck(:customer_id)
                                                       .compact

      # Also get customers from subscription templates
      customer_ids_from_templates = []
      if defined?(SubscriptionTemplate)
        customer_ids_from_templates = SubscriptionTemplate.where(delivery_person_id: delivery_person_id)
                                                         .distinct
                                                         .pluck(:customer_id)
                                                         .compact
      end

      # Combine all customer IDs from subscriptions
      all_customer_ids = (customer_ids_from_subscriptions + customer_ids_from_templates).uniq

      if all_customer_ids.any?
        base_query = base_query.where(customer_id: all_customer_ids)
      else
        # If no customers found for this delivery person, return empty result
        base_query = base_query.none
      end
    end

    # Apply status filter
    if params[:status].present? && params[:status] != 'all'
      if params[:status] == 'pending'
        base_query = base_query.where(payment_status: ['unpaid', 'partially_paid'])
      else
        base_query = base_query.where(payment_status: params[:status])
      end
    end

    # Apply date range filter
    if params[:date_from].present?
      date_column = table_name == 'invoices' ? 'invoice_date' : 'invoice_date'
      base_query = base_query.where("#{table_name}.#{date_column} >= ?", Date.parse(params[:date_from]))
    end

    if params[:date_to].present?
      date_column = table_name == 'invoices' ? 'invoice_date' : 'invoice_date'
      base_query = base_query.where("#{table_name}.#{date_column} <= ?", Date.parse(params[:date_to]))
    end

    # No limit here - we need all records for accurate stats
    base_query
  end

  def prepare_invoice_data(invoice, type)
    {
      id: invoice.id,
      invoice_number: invoice.invoice_number,
      customer_name: invoice.customer&.display_name || 'N/A',
      customer_mobile: invoice.customer&.mobile,
      total_amount: invoice.total_amount,
      paid_amount: invoice.paid_amount || 0,
      payment_status: invoice.payment_status,
      status: invoice.status,
      invoice_date: invoice.invoice_date || invoice.created_at&.to_date,
      created_at: invoice.created_at,
      type: type,
      model_object: invoice,
      booking_number: type == 'booking' ? invoice.booking&.booking_number : invoice.related_booking&.booking_number,
      from_booking: type == 'booking' || invoice.from_booking?
    }
  end

  def calculate_regular_invoice_stats_only
    # Calculate stats from regular invoices only (exclude booking invoices)
    regular_query = build_regular_invoices_query_for_stats

    {
      total_invoices: regular_query.count,
      total_amount: regular_query.sum(:total_amount) || 0,
      paid_amount: regular_query.where(payment_status: ['paid', 'fully_paid']).sum(:total_amount) || 0,
      pending_amount: regular_query.where(payment_status: ['unpaid', 'partially_paid']).sum(:total_amount) || 0,
      paid_count: regular_query.where(payment_status: ['paid', 'fully_paid']).count,
      pending_count: regular_query.where(payment_status: ['unpaid', 'partially_paid']).count
    }
  end

  def calculate_combined_invoice_stats
    # Calculate stats from full database, not just paginated results
    invoice_type = params[:type] || 'regular'

    # Get full queries without limits for accurate stats
    regular_stats = { total_amount: 0, paid_amount: 0, pending_amount: 0, total_count: 0, paid_count: 0, pending_count: 0 }
    booking_stats = { total_amount: 0, paid_amount: 0, pending_amount: 0, total_count: 0, paid_count: 0, pending_count: 0 }

    if ['all', 'regular'].include?(invoice_type)
      regular_query = build_regular_invoices_query_for_stats
      regular_stats = {
        total_count: regular_query.count,
        total_amount: regular_query.sum(:total_amount) || 0,
        paid_amount: regular_query.where(payment_status: ['paid', 'fully_paid']).sum(:total_amount) || 0,
        pending_amount: regular_query.where(payment_status: ['unpaid', 'partially_paid']).sum(:total_amount) || 0,
        paid_count: regular_query.where(payment_status: ['paid', 'fully_paid']).count,
        pending_count: regular_query.where(payment_status: ['unpaid', 'partially_paid']).count
      }
    end

    if ['all', 'booking'].include?(invoice_type)
      booking_query = build_booking_invoices_query_for_stats
      booking_stats = {
        total_count: booking_query.count,
        total_amount: booking_query.sum(:total_amount) || 0,
        paid_amount: booking_query.where(payment_status: ['paid', 'fully_paid']).sum(:total_amount) || 0,
        pending_amount: booking_query.where(payment_status: ['unpaid', 'partially_paid']).sum(:total_amount) || 0,
        paid_count: booking_query.where(payment_status: ['paid', 'fully_paid']).count,
        pending_count: booking_query.where(payment_status: ['unpaid', 'partially_paid']).count
      }
    end

    {
      total_invoices: regular_stats[:total_count] + booking_stats[:total_count],
      total_amount: regular_stats[:total_amount] + booking_stats[:total_amount],
      paid_amount: regular_stats[:paid_amount] + booking_stats[:paid_amount],
      pending_amount: regular_stats[:pending_amount] + booking_stats[:pending_amount],
      paid_count: regular_stats[:paid_count] + booking_stats[:paid_count],
      pending_count: regular_stats[:pending_count] + booking_stats[:pending_count]
    }
  end

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def get_pending_items_summary(customer_selection, customer_ids, delivery_person_id)
    # Determine which customers to check based on selection criteria
    customers = []
    if customer_selection == 'all'
      customers = Customer.all
    elsif customer_selection == 'delivery_person' && delivery_person_id.present?
      # Get customers who have bookings or subscriptions with the selected delivery person
      customer_ids_from_bookings = Booking.where(delivery_person_id: delivery_person_id)
                                         .distinct
                                         .pluck(:customer_id)
                                         .compact

      customer_ids_from_subscriptions = []
      if defined?(MilkSubscription)
        customer_ids_from_subscriptions += MilkSubscription.where(delivery_person_id: delivery_person_id)
                                                          .distinct
                                                          .pluck(:customer_id)
                                                          .compact
      end

      if defined?(SubscriptionTemplate)
        customer_ids_from_subscriptions += SubscriptionTemplate.where(delivery_person_id: delivery_person_id)
                                                               .distinct
                                                               .pluck(:customer_id)
                                                               .compact
      end

      all_customer_ids_from_delivery_person = (customer_ids_from_bookings + customer_ids_from_subscriptions).uniq

      if customer_ids.present?
        final_customer_ids = all_customer_ids_from_delivery_person & customer_ids.map(&:to_i)
        customers = Customer.where(id: final_customer_ids)
      else
        customers = Customer.where(id: all_customer_ids_from_delivery_person)
      end
    else
      customers = Customer.where(id: customer_ids)
    end

    # Get pending amounts for the selected customers - only include unresolved pending amounts
    pending_amounts = PendingAmount.joins(:customer)
                                   .where(customer: customers)
                                   .current_pending

    # Build summary
    summary = {
      total_count: pending_amounts.count,
      total_amount: pending_amounts.sum(:amount),
      customers_count: pending_amounts.distinct.count(:customer_id),
      from_date: 'All time',
      to_date: Date.current.strftime('%Y-%m-%d'),
      breakdown: []
    }

    # Group by customer for breakdown
    customer_breakdown = pending_amounts.joins(:customer)
                                       .group('customers.id', 'customers.first_name', 'customers.last_name')
                                       .select('customers.id, customers.first_name, customers.last_name, COUNT(*) as count, SUM(amount) as total')

    customer_breakdown.each do |item|
      summary[:breakdown] << {
        customer_id: item.id,
        customer_name: "#{item.first_name} #{item.last_name}".strip,
        pending_count: item.count,
        pending_amount: item.total
      }
    end

    summary
  end

  def invoice_params
    params.require(:invoice).permit(:invoice_date, :due_date, :status, :payment_status, :total_amount,
                                   invoice_items_attributes: [:id, :product_id, :description, :quantity, :unit_price, :total_amount, :_destroy])
  end

  def update_related_booking_stock(original_quantities)
    # Find booking related to this invoice
    related_booking = Booking.find_by(invoice_number: @invoice.invoice_number)
    return unless related_booking

    # Track which invoice items have been processed to avoid conflicts
    processed_products = Set.new

    @invoice.invoice_items.each do |invoice_item|
      next unless invoice_item.product
      next if processed_products.include?(invoice_item.product_id)

      # Find corresponding booking item
      booking_item = related_booking.booking_items.find_by(product_id: invoice_item.product_id)
      next unless booking_item

      # Calculate quantity difference for this invoice item
      original_qty = original_quantities[invoice_item.id] || 0
      invoice_qty_difference = invoice_item.quantity - original_qty

      if invoice_qty_difference != 0
        # Update the booking item quantity to match invoice item
        new_booking_qty = booking_item.quantity + invoice_qty_difference

        if new_booking_qty > 0
          # Update booking item quantity (this will trigger its stock update callbacks)
          booking_item.update!(quantity: new_booking_qty)
        else
          # If quantity becomes 0 or negative, remove the booking item
          booking_item.destroy!
        end

        processed_products.add(invoice_item.product_id)
      end
    end

    # Handle removed invoice items (items that were deleted from invoice)
    invoice_items_attributes = invoice_params[:invoice_items_attributes]
    if invoice_items_attributes
      invoice_items_attributes.each do |_, item_attrs|
        if item_attrs['_destroy'] == '1' && item_attrs['id'].present? && item_attrs['product_id'].present?
          # This invoice item was deleted, find corresponding booking item
          booking_item = related_booking.booking_items.find_by(product_id: item_attrs['product_id'])
          if booking_item
            # Remove the booking item as well to keep them in sync
            booking_item.destroy!
          end
        end
      end
    end

    # Recalculate booking totals
    related_booking.reload
    new_booking_total = related_booking.booking_items.sum { |item| item.quantity * item.price }
    related_booking.update!(total_amount: new_booking_total)
  end

  def generate_customer_invoice(customer, month, year)
    start_date = Date.new(year, month).beginning_of_month
    end_date = Date.new(year, month).end_of_month

    # Check if invoice already exists for this month (using new month/year columns for better performance)
    existing_invoice = Invoice.where(customer: customer, month: month, year: year).last

    # If invoice exists, only proceed if there are uninvoiced items for this month
    if existing_invoice
      # Check for uninvoiced MilkDeliveryTasks
      has_uninvoiced_tasks = false
      if defined?(MilkDeliveryTask)
        has_uninvoiced_tasks = MilkDeliveryTask.where(
          customer: customer,
          delivery_date: start_date..end_date,
          invoiced: [false, nil]
        ).exists?
      end

      # Check for uninvoiced bookings
      has_uninvoiced_bookings = customer.bookings
                                       .where(booking_date: start_date..end_date)
                                       .where(status: ['completed', 'delivered'])
                                       .where(payment_status: [nil, '', 'unpaid'])
                                       .where(invoice_generated: [false, nil])
                                       .where.not(id: BookingInvoice.select(:booking_id).where.not(booking_id: nil))
                                       .exists?

      # Check for uninvoiced pending amounts
      has_pending_amounts = PendingAmount.where(customer: customer)
                                         .where(pending_date: start_date..end_date)
                                         .current_pending
                                         .exists?

      # If no uninvoiced items, return existing invoice
      unless has_uninvoiced_tasks || has_uninvoiced_bookings || has_pending_amounts
        return existing_invoice
      end

      # If there are uninvoiced items, we'll create a NEW invoice for them
      # Don't modify the existing invoice - just continue to create a new one
    end

    invoice_items_data = []
    total_pending_from_previous = 0

    # STEP 1: Handle previous unpaid/partially paid invoices
    # Only include previous invoice amounts if this is the FIRST invoice for this month
    unless existing_invoice
      previous_invoices = customer.invoices
                                 .where('invoice_date < ?', start_date)
                                 .where(
                                   "(paid_amount < total_amount OR paid_amount IS NULL) AND status IN (?, ?, ?)",
                                   'draft', 'partially_paid', 'moved_to_next_month'
                                 )

      previous_invoices.each do |prev_invoice|
        pending_amount = prev_invoice.remaining_amount
        if pending_amount > 0
          total_pending_from_previous += pending_amount

          # Mark the old invoice as moved to next month
          prev_invoice.update!(status: 'moved_to_next_month')

          # Add pending amount as a line item
          invoice_items_data << {
            product: nil,
            quantity: 1,
            unit_price: pending_amount,
            description: "Pending from previous invoice ##{prev_invoice.invoice_number} (#{prev_invoice.invoice_date.strftime('%b %Y')})",
            is_pending_amount: true
          }
        end
      end
    end

    # 1. Find unpaid, not invoiced, completed bookings for the customer in the specified month
    # Check only amount after discount as requested
    unpaid_bookings = customer.bookings
                             .where(booking_date: start_date..end_date)
                             .where(status: ['completed', 'delivered'])
                             .where(payment_status: [nil, '', 'unpaid'])
                             .where(invoice_generated: [false, nil])
                             .where.not(id: BookingInvoice.select(:booking_id).where.not(booking_id: nil))

    # Process unpaid bookings - add individual line items for each booking item
    unpaid_bookings.each do |booking|
      booking.booking_items.includes(:product).each do |item|
        product = item.product
        next unless product

        # Use full selling price including GST
        unit_price = item.price || product.selling_price

        # Apply any booking-level discount proportionally
        if booking.discount_amount.to_f > 0 && booking.total_amount.to_f > 0
          discount_ratio = booking.discount_amount.to_f / booking.total_amount.to_f
          unit_price = unit_price * (1 - discount_ratio)
        end

        invoice_items_data << {
          product: product,
          quantity: item.quantity,
          unit_price: unit_price,
          description: "#{product.name} - Booking ##{booking.booking_number} (#{booking.booking_date.strftime('%d %b %Y')})",
          booking_item: item,
          booking: booking
        }
      end
    end

    # 2. Check pending amounts for this customer for date range and check the line items pending
    pending_amounts = PendingAmount.where(customer: customer)
                                  .where(pending_date: start_date..end_date)
                                  .current_pending

    # Add pending amounts as line items
    pending_amounts.each do |pending_amount|
      invoice_items_data << {
        product: nil,
        quantity: 1,
        unit_price: pending_amount.amount,
        description: "Pending Amount: #{pending_amount.description} (#{pending_amount.pending_date&.strftime('%d %b %Y') || pending_amount.created_at.strftime('%d %b %Y')})",
        pending_amount: pending_amount
      }
    end

    # 3. Check MilkDeliveryTask if we have any pending for month check
    if defined?(MilkDeliveryTask)
      pending_delivery_tasks = MilkDeliveryTask.joins(:product)
                                              .where(customer: customer,
                                                     delivery_date: start_date..end_date)
                                              .where(status: ['pending', 'scheduled', 'completed'])
                                              .where(invoiced: [false, nil])

      # Group pending delivery tasks by product and sum quantities
      grouped_pending_tasks = pending_delivery_tasks.group_by(&:product)

      grouped_pending_tasks.each do |product, tasks|
        total_quantity = tasks.sum(&:quantity)

        # Use full selling price including GST
        unit_price = product.selling_price

        # Get date range for description
        dates = tasks.map(&:delivery_date).sort
        date_range = if dates.size > 1
          "#{dates.first.strftime('%Y-%m-%d')} to #{dates.last.strftime('%Y-%m-%d')}"
        else
          dates.first.strftime('%Y-%m-%d')
        end

        invoice_items_data << {
          product: product,
          quantity: total_quantity,
          unit_price: unit_price,
          description: "#{product.name} - Milk Deliveries (#{dates.size} tasks: #{date_range})",
          delivery_tasks: tasks
        }
      end
    end

    # Don't return nil if we have pending amounts from previous invoices
    return nil if invoice_items_data.empty? && total_pending_from_previous == 0

    # Always create a NEW invoice (don't modify existing ones)
    invoice = Invoice.new(
      customer: customer,
      invoice_date: end_date,
      due_date: Date.current + 5.days,
      status: :draft,
      payment_status: :unpaid,
      month: month,
      year: year
    )

    total_amount = 0

    # Create invoice items
    invoice_items_data.each do |item_data|
      item_total = item_data[:quantity] * item_data[:unit_price]

      # For grouped delivery tasks, we'll link to the first task
      # (we could also create a separate junction table, but this is simpler for now)
      delivery_task = if item_data[:delivery_tasks]
                       item_data[:delivery_tasks].first
                     else
                       item_data[:delivery_task]
                     end

      invoice_item = invoice.invoice_items.build(
        description: item_data[:description],
        quantity: item_data[:quantity],
        unit_price: item_data[:unit_price],
        total_amount: item_total,
        product: item_data[:product],
        milk_delivery_task: delivery_task
      )

      # Store reference to pending amount for later processing
      invoice_item.instance_variable_set(:@pending_amount, item_data[:pending_amount]) if item_data[:pending_amount]

      total_amount += item_total
    end

    invoice.total_amount = total_amount

    if invoice.save
      # Mark delivery tasks as invoiced if applicable
      if defined?(MilkDeliveryTask)
        invoice_items_data.each do |item_data|
          # Handle both single tasks and grouped tasks
          tasks_to_mark = if item_data[:delivery_tasks]
                           item_data[:delivery_tasks]
                         elsif item_data[:delivery_task]
                           [item_data[:delivery_task]]
                         else
                           []
                         end

          tasks_to_mark.each do |task|
            task.update(invoiced: true, invoiced_at: Time.current) if task
          end
        end
      end

      # Mark bookings as invoiced (avoid duplicates)
      invoiced_bookings = Set.new
      invoice_items_data.each do |item_data|
        if item_data[:booking] && !invoiced_bookings.include?(item_data[:booking].id)
          item_data[:booking].update!(
            invoice_generated: true,
            invoice_number: invoice.invoice_number
          )
          invoiced_bookings.add(item_data[:booking].id)
        end
      end

      # Mark pending amounts as resolved since they're now included in the invoice
      invoice_items_data.each do |item_data|
        if item_data[:pending_amount]
          # Build update attributes based on available columns
          update_attributes = {
            status: :resolved
          }

          # Add resolution information to notes field (append, don't replace)
          resolution_info = "Resolved via Invoice ##{invoice.invoice_number} on #{Time.current.strftime('%Y-%m-%d')}"
          existing_notes = item_data[:pending_amount].notes.present? ? item_data[:pending_amount].notes : ""

          if existing_notes.present?
            update_attributes[:notes] = "#{existing_notes} | #{resolution_info}"
          else
            update_attributes[:notes] = resolution_info
          end

          # Add resolved_at if the column exists
          if item_data[:pending_amount].respond_to?(:resolved_at)
            update_attributes[:resolved_at] = Time.current
          end

          item_data[:pending_amount].update!(update_attributes)
        end
      end

      return invoice
    else
      raise invoice.errors.full_messages.join(', ')
    end
  end

  def calculate_invoice_stats(query)
    stats = query.group(:payment_status).sum(:total_amount)

    {
      total_invoices: query.count,
      total_amount: query.sum(:total_amount) || 0,
      paid_amount: stats['fully_paid'] || 0,
      pending_amount: (stats['unpaid'] || 0) + (stats['partially_paid'] || 0),
      partially_paid_amount: stats['partially_paid'] || 0,
      paid_count: query.where(payment_status: 'fully_paid').count,
      pending_count: query.where(payment_status: ['unpaid', 'partially_paid']).count,
      this_month_count: query.where(invoice_date: Date.current.beginning_of_month..Date.current.end_of_month).count,
      this_month_amount: query.where(invoice_date: Date.current.beginning_of_month..Date.current.end_of_month).sum(:total_amount) || 0
    }
  end
end