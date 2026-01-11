class Booking < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :user, optional: true # Admin who created the booking
  belongs_to :booking_schedule, optional: true # For subscription bookings
  has_many :booking_items, dependent: :destroy
  has_one :order, dependent: :nullify
  has_many :booking_invoices, dependent: :destroy

  accepts_nested_attributes_for :booking_items, allow_destroy: true


  # Enums - Comprehensive status for complete workflow
  enum :status, {
    draft: 'draft',                                 # Initial booking creation
    ordered_and_delivery_pending: 'ordered_and_delivery_pending', # Order placed, waiting for processing
    confirmed: 'confirmed',                         # Booking confirmed, payment received
    processing: 'processing',                       # Order being prepared
    packed: 'packed',                               # Items packed and ready
    shipped: 'shipped',                             # Shipped out
    out_for_delivery: 'out_for_delivery',          # Out for delivery
    delivered: 'delivered',                         # Successfully delivered
    completed: 'completed',                         # Transaction completed
    cancelled: 'cancelled',                         # Cancelled
    returned: 'returned'                           # Returned
  }

  enum :payment_status, {
    unpaid: 0,
    paid: 1,
    partially_paid: 2,
    refunded: 3
  }, prefix: true

  enum :payment_method, {
    cash: 0,
    card: 1,
    upi: 2,
    bank_transfer: 3,
    online: 4
  }, prefix: true

  # Validations
  validates :booking_number, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_booking_number, on: :create
  before_validation :calculate_totals

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :active, -> { where.not(status: [:cancelled, :returned]) }
  scope :completed_orders, -> { where(status: [:delivered, :completed]) }
  scope :pending_orders, -> { where(status: [:draft, :ordered_and_delivery_pending, :confirmed]) }
  scope :in_progress, -> { where(status: [:processing, :packed, :shipped, :out_for_delivery]) }

  def generate_booking_number
    self.booking_number ||= "BK#{Date.current.strftime('%Y%m%d')}#{SecureRandom.hex(3).upcase}"
  end

  def generate_invoice_number
    return if invoice_number.present?

    self.invoice_number = "INV#{Date.current.strftime('%Y%m%d')}#{SecureRandom.hex(3).upcase}"
    self.invoice_generated = true

    # Save the booking first
    if save
      # Create the BookingInvoice record
      create_booking_invoice_record
    end
  end

  def create_booking_invoice_record
    return if booking_invoices.any? # Avoid duplicates

    booking_invoices.create!(
      customer: self.customer,
      invoice_number: self.invoice_number,
      invoice_date: Time.current,
      due_date: 30.days.from_now,
      subtotal: self.subtotal || 0,
      tax_amount: self.tax_amount || 0,
      discount_amount: self.discount_amount || 0,
      total_amount: self.total_amount || 0,
      payment_status: self.payment_status || :unpaid,
      status: :sent,
      notes: "Invoice generated for booking ##{self.booking_number}"
    )
  rescue => e
    Rails.logger.error "Failed to create BookingInvoice for Booking ##{id}: #{e.message}"
    # Don't fail the booking creation if invoice creation fails
  end

  def calculate_totals
    # Calculate totals for items (including unsaved ones)
    items_total = 0
    booking_items.each do |item|
      if item.quantity.present? && item.price.present?
        items_total += (item.quantity * item.price)
      end
    end

    self.subtotal = items_total
    self.tax_amount = (subtotal * 0.18).round(2) # 18% GST
    self.total_amount = (subtotal + tax_amount - (discount_amount || 0)).round(2)
  end

  def calculate_totals!
    calculate_totals
    save!
  end

  # Dynamic calculation methods for invoice display
  def calculated_subtotal
    return subtotal if subtotal.present?

    total = booking_items.sum { |item| (item.quantity || 0) * (item.price || 0) }
    total.round(2)
  end

  def calculated_tax_amount
    return tax_amount if tax_amount.present?

    (calculated_subtotal * 0.18).round(2)
  end

  def calculated_total_amount
    return total_amount if total_amount.present?

    (calculated_subtotal + calculated_tax_amount - (discount_amount || 0)).round(2)
  end

  def amount_in_words
    amount = calculated_total_amount.to_i
    convert_to_words(amount) + " Rupees Only"
  end

  # Status management methods
  def can_cancel?
    %w[draft ordered_and_delivery_pending confirmed processing].include?(status)
  end

  def can_return?
    %w[delivered completed].include?(status)
  end

  def mark_as_confirmed!
    update!(status: :confirmed) if draft? || ordered_and_delivery_pending?
  end

  def mark_as_processing!
    update!(status: :processing) if confirmed?
  end

  def mark_as_packed!
    update!(status: :packed) if processing?
  end

  def mark_as_shipped!(tracking_number = nil)
    if packed?
      updates = { status: :shipped }
      updates[:notes] = "#{notes}\nTracking: #{tracking_number}" if tracking_number.present?
      update!(updates)
    end
  end

  def mark_as_out_for_delivery!
    update!(status: :out_for_delivery) if shipped?
  end

  def mark_as_delivered!
    if out_for_delivery?
      update!(
        status: :delivered,
        notes: "#{notes}\nDelivered at: #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
      )
      # Auto-transition to completed when delivered (as per user requirement)
      mark_as_completed!
    end
  end

  def mark_as_completed!
    update!(status: :completed) if delivered?
  end

  def cancel_order!(reason = nil)
    if can_cancel?
      cancel_notes = reason.present? ? "Cancelled: #{reason}" : "Cancelled"
      update!(
        status: :cancelled,
        notes: "#{notes}\n#{cancel_notes} at #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
      )
    end
  end

  def return_order!(reason = nil)
    if can_return?
      return_notes = reason.present? ? "Returned: #{reason}" : "Returned"
      update!(
        status: :returned,
        notes: "#{notes}\n#{return_notes} at #{Time.current.strftime('%d/%m/%Y %I:%M %p')}"
      )
    end
  end

  # Display helpers
  def status_color
    case status
    when 'draft', 'ordered_and_delivery_pending' then 'secondary'
    when 'confirmed' then 'info'
    when 'processing', 'packed' then 'warning'
    when 'shipped', 'out_for_delivery' then 'primary'
    when 'delivered', 'completed' then 'success'
    when 'cancelled', 'returned' then 'danger'
    else 'secondary'
    end
  end

  def status_icon
    case status
    when 'draft' then 'bi-pencil'
    when 'ordered_and_delivery_pending' then 'bi-clock'
    when 'confirmed' then 'bi-check-circle'
    when 'processing' then 'bi-gear'
    when 'packed' then 'bi-box'
    when 'shipped' then 'bi-truck'
    when 'out_for_delivery' then 'bi-geo-alt'
    when 'delivered' then 'bi-house-check'
    when 'completed' then 'bi-check-all'
    when 'cancelled' then 'bi-x-circle'
    when 'returned' then 'bi-arrow-return-left'
    else 'bi-question-circle'
    end
  end

  def next_possible_statuses
    case status
    when 'draft' then ['ordered_and_delivery_pending', 'confirmed', 'cancelled']
    when 'ordered_and_delivery_pending' then ['confirmed', 'cancelled']
    when 'confirmed' then ['processing', 'cancelled']
    when 'processing' then ['packed', 'cancelled']
    when 'packed' then ['shipped']
    when 'shipped' then ['out_for_delivery']
    when 'out_for_delivery' then ['delivered']
    when 'delivered' then ['returned']  # Auto-transitions to completed, so only return is possible
    else []
    end
  end

  private

  def convert_to_words(number)
    return "Zero" if number == 0

    ones = %w[Zero One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve Thirteen Fourteen Fifteen Sixteen Seventeen Eighteen Nineteen]
    tens = %w[Zero Ten Twenty Thirty Forty Fifty Sixty Seventy Eighty Ninety]

    result = []

    # Handle thousands
    if number >= 1000
      thousands = number / 1000
      if thousands >= 100
        result << ones[thousands / 100]
        result << "Hundred"
        thousands %= 100
      end

      if thousands >= 20
        result << tens[thousands / 10]
        thousands %= 10
      end

      if thousands > 0
        result << ones[thousands]
      end

      result << "Thousand"
      number %= 1000
    end

    # Handle hundreds
    if number >= 100
      result << ones[number / 100]
      result << "Hundred"
      number %= 100
    end

    # Handle tens and ones
    if number >= 20
      result << tens[number / 10]
      number %= 10
    end

    if number > 0
      result << ones[number]
    end

    result.join(" ")
  end

end
