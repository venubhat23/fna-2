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

  def bulk_invoice_form
    @customers = Customer.order(:first_name, :last_name)
    render layout: false
  end

  def generate_bulk_invoices
    month = params[:month].to_i
    year = params[:year].to_i
    customer_ids = params[:customer_ids]

    if customer_ids == 'all'
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
        message: "Generated #{generated_invoices.count} invoices successfully",
        errors: errors,
        invoices: generated_invoices.map { |inv| { id: inv.id, number: inv.invoice_number, customer: inv.customer.display_name, amount: inv.total_amount } }
      }
    else
      render json: {
        success: false,
        message: "No invoices could be generated",
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

    # Find completed delivery tasks for the customer in the specified month
    completed_tasks = MilkDeliveryTask.where(customer: customer,
                                           delivery_date: start_date..end_date,
                                           status: 'completed',
                                           invoiced: false)

    return nil if completed_tasks.empty?

    # Check if invoice already exists for this month
    existing_invoice = Invoice.where(customer: customer)
                             .where(invoice_date: start_date..end_date)
                             .first

    return existing_invoice if existing_invoice

    # Create new invoice
    invoice = Invoice.new(
      customer: customer,
      invoice_date: end_date,
      due_date: end_date + 30.days,
      status: :draft,
      payment_status: :unpaid,
      created_by: current_user.id,
      notes: "Monthly delivery invoice for #{Date::MONTHNAMES[month]} #{year}"
    )

    total_amount = 0

    # Group tasks by product for cleaner invoice items
    completed_tasks.group_by(&:product).each do |product, tasks|
      total_quantity = tasks.sum(&:quantity)
      unit_price = product.price || 30
      item_total = total_quantity * unit_price

      invoice.invoice_items.build(
        description: "#{product.name} - #{tasks.count} deliveries",
        quantity: total_quantity,
        unit_price: unit_price,
        total_amount: item_total
      )

      total_amount += item_total
    end

    invoice.total_amount = total_amount

    if invoice.save
      # Mark tasks as invoiced
      completed_tasks.update_all(invoiced: true, invoiced_at: Time.current)
      return invoice
    else
      raise invoice.errors.full_messages.join(', ')
    end
  end
end