class BookingSchedule < ApplicationRecord
  belongs_to :customer
  belongs_to :product
  has_many :bookings, dependent: :destroy

  validates :schedule_type, presence: true, inclusion: { in: %w[subscription recurring] }
  validates :frequency, presence: true, inclusion: { in: %w[daily weekly monthly] }
  validates :start_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :delivery_address, presence: true
  validates :pincode, presence: true, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }
  validates :status, presence: true, inclusion: { in: %w[active paused cancelled completed] }

  scope :active, -> { where(status: 'active') }
  scope :paused, -> { where(status: 'paused') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :completed, -> { where(status: 'completed') }
  scope :due_today, -> { where(next_booking_date: Date.current) }
  scope :overdue, -> { where('next_booking_date < ?', Date.current) }

  before_create :set_next_booking_date
  after_update :update_next_booking_date, if: :saved_change_to_frequency?

  def generate_next_booking!
    return unless active? && next_booking_date <= Date.current

    booking = Booking.create!(
      customer: customer,
      booking_date: Time.current,
      status: 'pending',
      payment_method: 'cash_on_delivery',
      payment_status: 'pending',
      customer_name: customer.display_name,
      customer_email: customer.email,
      customer_phone: customer.mobile,
      delivery_address: delivery_address,
      booking_schedule_id: id
    )

    booking.booking_items.create!(
      product: product,
      quantity: quantity,
      price: product.selling_price,
      total: product.selling_price * quantity
    )

    booking.calculate_totals!
    increment!(:total_bookings_generated)
    update_next_booking_date!

    booking
  end

  def pause!
    update!(status: 'paused')
  end

  def resume!
    update!(status: 'active')
    update_next_booking_date!
  end

  def cancel!
    update!(status: 'cancelled')
  end

  private

  def set_next_booking_date
    self.next_booking_date = start_date
  end

  def update_next_booking_date!
    return unless active?

    self.next_booking_date = case frequency
    when 'daily'
      next_booking_date + 1.day
    when 'weekly'
      next_booking_date + 1.week
    when 'monthly'
      next_booking_date + 1.month
    end

    save! if changed?
  end
end
