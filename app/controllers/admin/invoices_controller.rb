class Admin::InvoicesController < Admin::ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy]

  def index
    @invoices = Invoice.includes(:customer, :invoice_items)
                      .order(created_at: :desc)
                      .limit(50)
  end

  def show
    @invoice_items = @invoice.invoice_items.includes(:milk_delivery_task)
  end

  def customers
    @customers = Customer.order(:first_name, :last_name)
                        .select(:id, :first_name, :middle_name, :last_name)
                        .map { |c| { id: c.id, display_name: c.display_name } }
    render json: @customers
  end

  def generate
    month = params[:month].to_i
    year = params[:year].to_i
    customer_selection = params[:customer_selection]
    customer_ids = params[:customer_ids]

    if customer_selection == 'all'
      customers = Customer.all
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
        invoices: generated_invoices.map { |inv| { id: inv.id, number: inv.invoice_number, customer: inv.customer.display_name, amount: inv.total_amount } }
      }
    else
      render json: {
        success: false,
        invoices_created: 0,
        error: "No invoices could be generated. " + (errors.any? ? errors.join(', ') : 'No completed deliveries found for the selected period.'),
        errors: errors
      }
    end
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
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

        invoice_items_data << {
          product: product,
          quantity: item.quantity,
          unit_price: item.price || product.selling_price,
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

      # Group delivery tasks by product
      completed_tasks.group_by(&:product).each do |product, tasks|
        total_quantity = tasks.sum(&:quantity)
        unit_price = product.selling_price

        invoice_items_data << {
          product: product,
          quantity: total_quantity,
          unit_price: unit_price,
          description: "#{product.name} - #{tasks.count} deliveries",
          delivery_tasks: tasks
        }
      end
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

      invoice.invoice_items.build(
        description: item_data[:description],
        quantity: item_data[:quantity],
        unit_price: item_data[:unit_price],
        total_amount: item_total,
        product: item_data[:product],
        milk_delivery_task: item_data[:delivery_tasks]&.first
      )

      total_amount += item_total
    end

    invoice.total_amount = total_amount

    if invoice.save
      # Mark delivery tasks as invoiced if applicable
      if defined?(MilkDeliveryTask)
        delivery_task_items = invoice_items_data.select { |item| item[:delivery_tasks] }
        delivery_task_items.each do |item_data|
          item_data[:delivery_tasks]&.each do |task|
            task.update(invoiced: true, invoiced_at: Time.current)
          end
        end
      end

      return invoice
    else
      raise invoice.errors.full_messages.join(', ')
    end
  end
end