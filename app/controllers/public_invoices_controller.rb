# app/controllers/public_invoices_controller.rb
class PublicInvoicesController < ApplicationController
  include ActionController::MimeResponds

  # Skip authentication for all actions in this controller
  skip_before_action :authenticate_user!
  # Skip CanCan load_and_authorize_resource since this controller doesn't follow standard resource naming
  skip_load_and_authorize_resource
  layout false

  before_action :find_invoice, only: [:show]

  private

  def find_invoice
    @invoice = Invoice.find_by!(share_token: params[:token])
    @customer = @invoice.customer
    @business_settings = SystemSetting.business_settings
  end

  public

  def show
    respond_to do |format|
      format.html { render template: 'public_invoices/show' }
      format.pdf do
        # Use the dedicated PDF template
        html = render_to_string(
          template: 'public_invoices/show_pdf',
          layout: false
        )

        pdf = WickedPdf.new.pdf_from_string(
          html,
          page_size: 'A4',
          orientation: 'Portrait',
          margin: { top: 10, bottom: 10, left: 10, right: 10 },
          dpi: 96
        )

        send_data(pdf,
                  filename: "Invoice_#{@invoice.invoice_number}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline')
      end
    end
  rescue ActiveRecord::RecordNotFound
    render template: 'public_invoices/not_found', status: :not_found
  end

  def index
    @invoices = Invoice.includes(:customer)

    if params[:customer_name].present?
      search_term = "%#{params[:customer_name].downcase}%"
      @invoices = @invoices.joins(:customer)
                          .where("LOWER(customers.first_name) LIKE ? OR LOWER(customers.last_name) LIKE ? OR LOWER(CONCAT(customers.first_name, ' ', customers.last_name)) LIKE ?", search_term, search_term, search_term)
    end

    if params[:month].present? && params[:month] != 'all'
      @invoices = @invoices.where("EXTRACT(MONTH FROM invoice_date) = ?", params[:month].to_i)
    end

    if params[:status].present? && params[:status] != 'all'
      @invoices = @invoices.where(status: params[:status])
    end

    case params[:sort_by]
    when 'amount_high_to_low'
      @invoices = @invoices.order(total_amount: :desc, created_at: :desc)
    when 'amount_low_to_high'
      @invoices = @invoices.order(total_amount: :asc, created_at: :desc)
    when 'date_newest'
      @invoices = @invoices.order(created_at: :desc)
    when 'date_oldest'
      @invoices = @invoices.order(created_at: :asc)
    else
      @invoices = @invoices.order(total_amount: :desc, created_at: :desc)
    end

    @invoices = @invoices.to_a

    invoices_without_tokens = @invoices.select { |invoice| invoice.share_token.blank? }
    if invoices_without_tokens.any?
      Invoice.transaction do
        invoices_without_tokens.each { |inv| inv.generate_share_token! }
      end
    end

    # Append booking-only invoices (invoice_generated: true, no Invoice record)
    invoiced_numbers = Invoice.pluck(:invoice_number).compact
    booking_invoices_query = Booking.includes(:customer)
                                    .where(invoice_generated: true)
                                    .where.not(invoice_number: [nil, ''])
                                    .where.not(invoice_number: invoiced_numbers)

    if params[:customer_name].present?
      s = "%#{params[:customer_name].downcase}%"
      booking_invoices_query = booking_invoices_query.joins(:customer)
        .where("LOWER(customers.first_name) LIKE ? OR LOWER(customers.last_name) LIKE ?", s, s)
    end

    booking_invoices_query.each do |booking|
      @invoices << BookingInvoiceProxy.new(booking, request)
    end

    @total_invoice_count = @invoices.size
  end

  def complete
    @invoice = Invoice.find(params[:id])

    if @invoice.update(status: 'paid', payment_status: 'fully_paid', paid_at: Time.current)
      render json: {
        success: true,
        message: "Invoice ##{@invoice.invoice_number} marked as completed successfully!"
      }
    else
      render json: {
        success: false,
        message: "Failed to complete invoice: #{@invoice.errors.full_messages.join(', ')}"
      }
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Invoice not found"
    }, status: :not_found
  end

  def destroy
    @invoice = Invoice.find(params[:id])
    invoice_number = @invoice.invoice_number

    # Delete the invoice
    @invoice.destroy!

    render json: {
      success: true,
      message: "Invoice ##{invoice_number} and all associated items deleted successfully!"
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Invoice not found"
    }, status: :not_found
  rescue => e
    render json: {
      success: false,
      message: "Failed to delete invoice: #{e.message}"
    }, status: :unprocessable_entity
  end
end