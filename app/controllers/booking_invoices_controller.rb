class BookingInvoicesController < ApplicationController
  # Skip authentication for public actions
  skip_before_action :authenticate_user!
  layout false

  def public_view
    @invoice = BookingInvoice.find_by!(share_token: params[:token])
    @booking = @invoice.booking
    @customer = @invoice.customer || @booking&.customer
    @invoice_items = @invoice.parsed_invoice_items

    # Get business settings
    @business_settings = SystemSetting.business_settings

    render template: 'booking_invoices/public_view'
  rescue ActiveRecord::RecordNotFound
    render template: 'booking_invoices/not_found'
  end

  def public_download_pdf
    @invoice = BookingInvoice.find_by!(share_token: params[:token])
    @booking = @invoice.booking
    @customer = @invoice.customer || @booking&.customer
    @invoice_items = @invoice.parsed_invoice_items

    # Get business settings
    @business_settings = SystemSetting.business_settings

    respond_to do |format|
      format.pdf do
        render pdf: "invoice-#{@invoice.invoice_number}",
               template: 'booking_invoices/public_view',
               layout: 'pdf',
               show_as_html: params[:debug].present?
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Invoice not found'
  end
end