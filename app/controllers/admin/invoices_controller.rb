class Admin::InvoicesController < Admin::ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :mark_as_paid]

  def index
    # Base query with includes
    base_query = Invoice.includes(:customer, :invoice_items)

    # Apply search filters
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_query = base_query.joins(:customer)
                            .where("invoices.invoice_number ILIKE ? OR
                                    customers.first_name ILIKE ? OR
                                    customers.last_name ILIKE ? OR
                                    customers.email ILIKE ? OR
                                    customers.mobile ILIKE ?",
                                   search_term, search_term, search_term, search_term, search_term)
    end

    # Apply status filter
    if params[:status].present? && params[:status] != 'all'
      base_query = base_query.where(payment_status: params[:status])
    end

    # Apply date range filter
    if params[:date_from].present?
      base_query = base_query.where('invoice_date >= ?', Date.parse(params[:date_from]))
    end

    if params[:date_to].present?
      base_query = base_query.where('invoice_date <= ?', Date.parse(params[:date_to]))
    end


    # Get filtered invoices with pagination
    @invoices = base_query.order(created_at: :desc)
                         .limit(params[:limit]&.to_i || 50)
                         .offset(params[:offset]&.to_i || 0)

    # Calculate summary statistics
    @stats = calculate_invoice_stats(base_query)

    # Get delivery persons for filter dropdown
    @delivery_persons = DeliveryPerson.active.order(:first_name, :last_name)
  end

  def show
    @invoice_items = @invoice.invoice_items.includes(:milk_delivery_task)
  end

  def edit
    @invoice_items = @invoice.invoice_items.includes(:product, :milk_delivery_task)
  end

  def update
    if @invoice.update(invoice_params)
      redirect_to admin_invoice_path(@invoice), notice: 'Invoice was successfully updated.'
    else
      @invoice_items = @invoice.invoice_items.includes(:product, :milk_delivery_task)
      render :edit, alert: 'Failed to update invoice.'
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

  def customers
    @customers = Customer.order(:first_name, :last_name)
                        .select(:id, :first_name, :middle_name, :last_name)
                        .map { |c| { id: c.id, display_name: c.display_name } }
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

  def generate
    month = params[:month].to_i
    year = params[:year].to_i
    customer_selection = params[:customer_selection]
    customer_ids = params[:customer_ids]
    delivery_person_id = params[:delivery_person_id]

    # Get pending items summary before generation
    pending_summary = get_pending_items_summary(customer_selection, customer_ids, delivery_person_id)

    if customer_selection == 'all'
      customers = Customer.all
    elsif customer_selection == 'delivery_person' && delivery_person_id.present?
      # Get customers who have bookings with the selected delivery person
      customer_ids_from_bookings = Booking.where(delivery_person_id: delivery_person_id)
                                         .distinct
                                         .pluck(:customer_id)
                                         .compact

      # Get customers who have subscriptions with the selected delivery person
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

      # Combine all customer IDs from bookings and subscriptions
      all_customer_ids_from_delivery_person = (customer_ids_from_bookings + customer_ids_from_subscriptions).uniq

      # If specific customers were also selected, use the intersection
      if customer_ids.present?
        final_customer_ids = all_customer_ids_from_delivery_person & customer_ids.map(&:to_i)
        customers = Customer.where(id: final_customer_ids)
      else
        customers = Customer.where(id: all_customer_ids_from_delivery_person)
      end
    else
      customers = Customer.where(id: customer_ids)
    end

    generated_invoices = []
    errors = []

    customers.find_each do |customer|
      begin
        invoice = generate_customer_invoice(customer, month, year)
        generated_invoices << invoice if invoice
      rescue => e
        errors << "#{customer.display_name}: #{e.message}"
      end
    end

    if generated_invoices.any?
      render json: {
        success: true,
        invoices_created: generated_invoices.count,
        message: "Generated #{generated_invoices.count} invoices successfully",
        errors: errors,
        pending_items_summary: pending_summary,
        invoices: generated_invoices.map { |inv| { id: inv.id, number: inv.invoice_number, customer: inv.customer.display_name, amount: inv.total_amount } }
      }
    else
      render json: {
        success: false,
        invoices_created: 0,
        error: "No invoices could be generated. " + (errors.any? ? errors.join(', ') : 'No completed deliveries found for the selected period.'),
        errors: errors,
        pending_items_summary: pending_summary
      }
    end
  end

  private

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

    # Get pending amounts for the selected customers - include ALL pending amounts
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
    params.require(:invoice).permit(:invoice_date, :due_date, :status, :payment_status, :notes, :total_amount)
  end

  def generate_customer_invoice(customer, month, year)
    start_date = Date.new(year, month).beginning_of_month
    end_date = Date.new(year, month).end_of_month

    # Check if invoice already exists for this month
    existing_invoice = Invoice.where(customer: customer)
                             .where(invoice_date: start_date..end_date)
                             .first

    return existing_invoice if existing_invoice

    invoice_items_data = []

    # 1. Find completed bookings for the customer in the specified month
    completed_bookings = customer.bookings.includes(booking_items: :product)
                               .where(booking_date: start_date..end_date)
                               .where(status: ['completed', 'delivered'])

    # Process completed bookings
    completed_bookings.each do |booking|
      booking.booking_items.each do |item|
        product = item.product
        next unless product

        # Calculate proper unit price (base price excluding GST for GST products)
        unit_price = if product.gst_enabled? && product.gst_percentage.present?
          product.calculate_base_price
        else
          item.price || product.selling_price
        end

        invoice_items_data << {
          product: product,
          quantity: item.quantity,
          unit_price: unit_price,
          description: "#{product.name} - Booking ##{booking.booking_number}",
          booking_item: item
        }
      end
    end

    # 2. Find completed delivery tasks if MilkDeliveryTask model exists
    if defined?(MilkDeliveryTask)
      completed_tasks = MilkDeliveryTask.joins(:product)
                                      .where(customer: customer,
                                             delivery_date: start_date..end_date,
                                             status: 'completed')
                                      .where.not(id: InvoiceItem.joins(:milk_delivery_task)
                                                              .select(:milk_delivery_task_id))

      # Group delivery tasks by product and sum quantities
      grouped_tasks = completed_tasks.group_by(&:product)

      grouped_tasks.each do |product, tasks|
        total_quantity = tasks.sum(&:quantity)

        # Calculate proper unit price (base price excluding GST for GST products)
        unit_price = if product.gst_enabled? && product.gst_percentage.present?
          product.calculate_base_price
        else
          product.selling_price
        end

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
          description: "#{product.name} (#{dates.size} deliveries: #{date_range})",
          delivery_tasks: tasks  # Changed from single task to multiple tasks
        }
      end
    end

    # 3. Check for pending amounts for this customer - include ALL pending amounts
    pending_amounts = PendingAmount.where(customer: customer)
                                  .current_pending

    # Add pending amounts as line items
    pending_amounts.each do |pending_amount|
      invoice_items_data << {
        product: nil,
        quantity: 1,
        unit_price: pending_amount.amount,
        description: "Pending from last month: #{pending_amount.description}",
        pending_amount: pending_amount
      }
    end

    return nil if invoice_items_data.empty?

    # Create new invoice
    invoice = Invoice.new(
      customer: customer,
      invoice_date: end_date,
      due_date: end_date + 30.days,
      status: :draft,
      payment_status: :unpaid
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

      # Mark pending amounts as resolved since they're now included in the invoice
      invoice_items_data.each do |item_data|
        if item_data[:pending_amount]
          # Build update attributes based on available columns
          update_attributes = {
            status: :resolved,
            notes: "#{item_data[:pending_amount].notes || ''} | Resolved via Invoice ##{invoice.invoice_number} on #{Time.current.strftime('%Y-%m-%d')}".strip
          }

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