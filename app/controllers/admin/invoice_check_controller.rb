class Admin::InvoiceCheckController < ApplicationController
  before_action :authenticate_user!
  before_action :set_page_info

  def index
    @delivery_persons = DeliveryPerson.active.order(:first_name, :last_name)
    @customers_data = []
    @selected_month = params[:month]&.to_i || Date.current.month
    @selected_year = params[:year]&.to_i || Date.current.year
    @selected_delivery_person_id = params[:delivery_person_id]

    # Generate month options for dropdown
    @month_options = (1..12).map do |month|
      [Date::MONTHNAMES[month], month]
    end

    # Generate year options (current year and 2 years back/forward)
    current_year = Date.current.year
    @year_options = ((current_year - 2)..(current_year + 2)).to_a
  end

  def check
    @selected_month = params[:month]&.to_i || Date.current.month
    @selected_year = params[:year]&.to_i || Date.current.year
    @selected_delivery_person_id = params[:delivery_person_id]

    @delivery_persons = DeliveryPerson.active.order(:first_name, :last_name)
    @month_options = (1..12).map { |month| [Date::MONTHNAMES[month], month] }
    current_year = Date.current.year
    @year_options = ((current_year - 2)..(current_year + 2)).to_a

    # Get customers based on subscription data
    customers_with_subscriptions = get_customers_for_check

    @customers_data = customers_with_subscriptions.map do |customer|
      # Check if invoice exists for this customer for the selected month
      invoice_exists = check_invoice_exists(customer, @selected_month, @selected_year)

      # Calculate total amount from subscriptions
      total_amount = calculate_customer_subscription_amount(customer, @selected_month, @selected_year)

      {
        customer: customer,
        invoice_exists: invoice_exists[:exists],
        invoice_link: invoice_exists[:invoice],
        total_amount: total_amount,
        has_subscriptions: total_amount > 0
      }
    end

    # Calculate invoice statistics for this month
    @invoice_stats = calculate_invoice_stats_for_month(@selected_month, @selected_year, @selected_delivery_person_id)

    render :index
  end

  def generate_invoice
    @customer = Customer.find(params[:customer_id])
    @selected_month = params[:month]&.to_i || Date.current.month
    @selected_year = params[:year]&.to_i || Date.current.year

    begin
      # Generate invoice for customer for the selected month
      invoice = generate_customer_invoice(@customer, @selected_month, @selected_year)

      if invoice
        flash[:notice] = "Invoice #{invoice.invoice_number} generated successfully for #{@customer.display_name}! Total: ₹#{number_with_precision(invoice.total_amount, precision: 2)}"

        # Redirect back to check with the same parameters to show updated statistics
        redirect_to admin_invoice_check_check_path(month: @selected_month, year: @selected_year, delivery_person_id: params[:delivery_person_id])
      else
        flash[:alert] = "No subscription data found for #{@customer.display_name} in #{Date::MONTHNAMES[@selected_month]} #{@selected_year}"
        redirect_to admin_invoice_check_check_path(month: @selected_month, year: @selected_year, delivery_person_id: params[:delivery_person_id])
      end
    rescue => e
      flash[:alert] = "Error generating invoice: #{e.message}"
      redirect_to admin_invoice_check_path(month: @selected_month, year: @selected_year, delivery_person_id: params[:delivery_person_id])
    end
  end

  private

  def set_page_info
    @page_title = "Invoice Check"
    @page_subtitle = "Check subscription invoices by month and delivery person"
  end

  def get_customers_for_check
    # Base query for customers with active subscriptions
    customer_query = Customer.joins(:milk_subscriptions)
                            .where(milk_subscriptions: { is_active: true })
                            .distinct

    # Filter by delivery person if selected
    if @selected_delivery_person_id.present?
      customer_query = customer_query.where(milk_subscriptions: { delivery_person_id: @selected_delivery_person_id })
    end

    customer_query.order(:first_name, :last_name)
  end

  def check_invoice_exists(customer, month, year)
    # Check in regular Invoice table first
    invoice = Invoice.joins(:invoice_items)
                   .where(customer: customer)
                   .where("EXTRACT(month FROM invoice_date) = ? AND EXTRACT(year FROM invoice_date) = ?", month, year)
                   .first

    if invoice
      return { exists: true, invoice: invoice }
    end

    # Check in BookingInvoice table
    booking_invoice = BookingInvoice.where(customer: customer)
                                  .where("EXTRACT(month FROM invoice_date) = ? AND EXTRACT(year FROM invoice_date) = ?", month, year)
                                  .first

    if booking_invoice
      return { exists: true, invoice: booking_invoice }
    end

    { exists: false, invoice: nil }
  end

  def calculate_customer_subscription_amount(customer, month, year)
    # Get all active subscriptions for this customer and delivery person (if selected)
    subscriptions = customer.milk_subscriptions.where(is_active: true)

    if @selected_delivery_person_id.present?
      subscriptions = subscriptions.where(delivery_person_id: @selected_delivery_person_id)
    end

    total_amount = 0

    subscriptions.each do |subscription|
      # Calculate days in the month for this subscription
      start_of_month = Date.new(year, month, 1)
      end_of_month = start_of_month.end_of_month

      # Only count subscriptions that were active during the target month
      subscription_start = [subscription.start_date, start_of_month].max
      subscription_end = subscription.end_date ? [subscription.end_date, end_of_month].min : end_of_month

      if subscription_start <= subscription_end
        days_in_month = (subscription_end - subscription_start + 1).to_i
        daily_rate = subscription.product&.selling_price || 0
        month_amount = days_in_month * subscription.quantity * daily_rate
        total_amount += month_amount
      end
    end

    total_amount
  end

  def generate_customer_invoice(customer, month, year)
    # Check if invoice already exists
    existing_invoice = check_invoice_exists(customer, month, year)
    return existing_invoice[:invoice] if existing_invoice[:exists]

    # Calculate total amount
    total_amount = calculate_customer_subscription_amount(customer, month, year)

    return nil if total_amount <= 0

    # Get month name for invoice number
    month_abbreviation = month.to_s.rjust(2, '0')  # Format as 01, 02, etc.

    # Generate unique invoice number with month
    invoice_number = generate_invoice_number_with_month(month)

    # Create invoice
    invoice = Invoice.create!(
      customer: customer,
      invoice_number: invoice_number,
      invoice_date: Date.new(year, month, -1), # Last day of the month
      due_date: Date.new(year, month, -1) + 5.days,
      total_amount: total_amount,
      subtotal: total_amount,
      tax_amount: 0,
      discount_amount: 0,
      status: :draft,
      payment_status: :unpaid
    )

    # Create invoice items from subscriptions
    customer.milk_subscriptions.where(is_active: true).each do |subscription|
      next if @selected_delivery_person_id.present? && subscription.delivery_person_id != @selected_delivery_person_id.to_i

      start_of_month = Date.new(year, month, 1)
      end_of_month = start_of_month.end_of_month

      subscription_start = [subscription.start_date, start_of_month].max
      subscription_end = subscription.end_date ? [subscription.end_date, end_of_month].min : end_of_month

      if subscription_start <= subscription_end
        days_in_month = (subscription_end - subscription_start + 1).to_i
        daily_rate = subscription.product&.selling_price || 0
        item_total = days_in_month * subscription.quantity * daily_rate

        if item_total > 0
          invoice.invoice_items.create!(
            product: subscription.product,
            description: "#{subscription.product&.name} - #{Date::MONTHNAMES[month]} #{year} (#{days_in_month} days)",
            quantity: subscription.quantity * days_in_month,
            unit_price: daily_rate,
            total_amount: item_total
          )
        end
      end
    end

    # Generate share token
    invoice.generate_share_token! if invoice.respond_to?(:generate_share_token!)

    invoice
  end

  def generate_invoice_number_with_month(month)
    Invoice.generate_invoice_number_for_month(month)
  end

  def calculate_invoice_stats_for_month(month, year, delivery_person_id = nil)
    # Get all invoices for this month and year
    regular_invoices = Invoice.where("EXTRACT(month FROM invoice_date) = ? AND EXTRACT(year FROM invoice_date) = ?", month, year)
    booking_invoices = BookingInvoice.where("EXTRACT(month FROM invoice_date) = ? AND EXTRACT(year FROM invoice_date) = ?", month, year)

    # If delivery person is selected, filter by customers with subscriptions from that delivery person
    if delivery_person_id.present?
      customer_ids = MilkSubscription.where(delivery_person_id: delivery_person_id, is_active: true)
                                    .distinct
                                    .pluck(:customer_id)
                                    .compact

      regular_invoices = regular_invoices.where(customer_id: customer_ids)
      booking_invoices = booking_invoices.where(customer_id: customer_ids)
    end

    # Calculate totals
    regular_count = regular_invoices.count
    regular_amount = regular_invoices.sum(:total_amount)

    booking_count = booking_invoices.count
    booking_amount = booking_invoices.sum(:total_amount)

    {
      total_count: regular_count + booking_count,
      total_amount: regular_amount + booking_amount,
      regular_invoices: {
        count: regular_count,
        amount: regular_amount
      },
      booking_invoices: {
        count: booking_count,
        amount: booking_amount
      }
    }
  end
end