class BookingInvoiceProxy
  attr_reader :booking, :request

  def initialize(booking, request = nil)
    @booking = booking
    @request = request
  end

  def id           = booking.id
  def invoice_number = booking.invoice_number
  def formatted_number = booking.invoice_number
  def total_amount = booking.total_amount || 0
  def paid_amount  = 0
  def status       = booking.payment_status == 'paid' ? 'paid' : 'unpaid'
  def payment_status = booking.payment_status || 'unpaid'
  def invoice_date = booking.booking_date&.to_date || booking.created_at&.to_date
  def due_date     = nil
  def created_at   = booking.created_at
  def updated_at   = booking.updated_at
  def share_token  = booking.invoice_number
  def notes        = nil

  def customer      = booking.customer
  def customer_name = booking.customer&.display_name || booking.customer_name || 'N/A'
  def customer_phone = booking.customer&.mobile || booking.customer_phone

  def from_booking? = true
  def overdue?      = false
  def changed?      = false

  def generate_share_token; end
  def generate_share_token!; end
  def save!; end

  def is_booking_proxy? = true

  # Public URL points to the booking invoice view
  def public_url(host)
    "/admin/bookings/#{booking.id}/invoice"
  end
end
