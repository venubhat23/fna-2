class Admin::InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :show_premium, :download_pdf, :download_premium_pdf, :mark_as_paid]

  def index
    @invoices = BookingInvoice.includes(:booking, :customer)
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(20)

    # Filter by payment status
    if params[:status].present?
      @invoices = @invoices.where(payment_status: params[:status])
    end

    # Filter by invoice status
    if params[:invoice_status].present?
      @invoices = @invoices.where(status: params[:invoice_status])
    end
  end

  def show
    @booking = @invoice.booking
    @customer = @invoice.customer || @booking.customer
    render template: 'admin/invoices/invoice_new', layout: false
  end

  def show_premium
    @booking = @invoice.booking
    @customer = @invoice.customer || @booking.customer
    render template: 'admin/invoices/invoice_new', layout: false
  end

  def generate_invoice
    payout_type = params[:payout_type]
    payout_id = params[:payout_id]

    case payout_type
    when 'affiliate'
      payout = CommissionPayout.find_by(id: payout_id, payout_to: 'affiliate')
    when 'distributor'
      payout = DistributorPayout.find(payout_id)
    when 'ambassador'
      payout = CommissionPayout.find_by(id: payout_id, payout_to: 'ambassador')
    when 'commission'
      payout = Payout.find(payout_id)
    else
      render json: { error: 'Invalid payout type' }, status: 400
      return
    end

    unless payout
      render json: { error: 'Payout record not found' }, status: 404
      return
    end

    # Check if invoice already exists for this payout
    existing_invoice = Invoice.find_by(payout_type: payout_type, payout_id: payout_id)
    if existing_invoice
      render json: { error: 'Invoice already exists for this payout' }, status: 422
      return
    end

    # Generate invoice
    invoice = Invoice.create!(
      invoice_number: generate_invoice_number,
      payout_type: payout_type,
      payout_id: payout_id,
      total_amount: calculate_total_amount(payout),
      status: 'pending',
      invoice_date: Date.current,
      due_date: Date.current + 30.days
    )

    # Mark the payout as invoiced
    payout.update!(invoiced: true) if payout.respond_to?(:invoiced)

    render json: {
      success: true,
      message: 'Invoice generated successfully',
      invoice_id: invoice.id,
      invoice_number: invoice.invoice_number
    }
  rescue => e
    render json: { error: e.message }, status: 500
  end

  def mark_as_paid
    @invoice.update!(
      status: 'paid',
      paid_at: Time.current
    )

    # Update the associated payout record
    payout = @invoice.payout_record
    if payout.respond_to?(:mark_as_paid!)
      payout.mark_as_paid!
    else
      payout.update!(status: 'paid', paid_at: Time.current)
    end

    redirect_to admin_invoices_path, notice: 'Invoice marked as paid successfully'
  rescue => e
    redirect_to admin_invoices_path, alert: "Error marking invoice as paid: #{e.message}"
  end

  def download_pdf
    respond_to do |format|
      format.pdf do
        render pdf: "invoice_#{@invoice.invoice_number}",
               template: 'admin/invoices/show',
               layout: false,
               page_size: 'A4',
               margin: { top: 5, bottom: 5, left: 5, right: 5 },
               encoding: 'UTF-8'
      end
    end
  rescue => e
    redirect_to admin_invoices_path, alert: "Error generating PDF: #{e.message}"
  end

  def download_premium_pdf
    respond_to do |format|
      format.pdf do
        render pdf: "premium_invoice_#{@invoice.invoice_number}",
               template: 'admin/invoices/show_premium',
               layout: false,
               page_size: 'A4',
               margin: { top: 10, bottom: 10, left: 10, right: 10 },
               encoding: 'UTF-8',
               javascript_delay: 1000
      end
    end
  rescue => e
    redirect_to admin_invoices_path, alert: "Error generating premium PDF: #{e.message}"
  end

  private

  def set_invoice
    @invoice = BookingInvoice.find(params[:id])
  end

  def generate_invoice_number
    "INV-#{Date.current.strftime('%Y%m%d')}-#{rand(10000..99999)}"
  end

  def calculate_total_amount(payout)
    case payout.class.name
    when 'CommissionPayout'
      payout.payout_amount || 0
    when 'DistributorPayout'
      payout.payout_amount || 0
    when 'Payout'
      payout.total_commission_amount || payout.total_amount || 0
    else
      0
    end
  end
end