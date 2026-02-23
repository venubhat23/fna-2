# app/controllers/public_invoices_controller.rb
class PublicInvoicesController < ApplicationController
  # Skip authentication for all actions in this controller
  skip_before_action :authenticate_user!
  # Skip CanCan load_and_authorize_resource since this controller doesn't follow standard resource naming
  skip_load_and_authorize_resource
  layout false

  def index
    # Start with optimized base query - include all needed associations
    @invoices = BookingInvoice.includes(:booking, :customer, booking: [:booking_items, booking_items: :product])

    # Apply filters
    if params[:customer_name].present?
      # Use case-insensitive search that works across databases
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

    # Apply sorting
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
      # Default: sort by highest amount first
      @invoices = @invoices.order(total_amount: :desc, created_at: :desc)
    end

    # Execute query and get results
    @invoices = @invoices.to_a

    # Batch update share tokens for invoices that don't have them
    invoices_without_tokens = @invoices.select { |invoice| invoice.share_token.blank? }
    if invoices_without_tokens.any?
      invoices_without_tokens.each(&:generate_share_token)
      BookingInvoice.transaction do
        invoices_without_tokens.each(&:save!)
      end
    end

    # Cache total count to avoid repeated queries
    @total_invoice_count = @invoices.size
  end

  def complete
    @invoice = BookingInvoice.find(params[:id])

    if @invoice.update(status: 'paid')
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
    @invoice = BookingInvoice.find(params[:id])
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