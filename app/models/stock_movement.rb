class StockMovement < ApplicationRecord
  # Movement type constants
  MOVEMENT_TYPES = [
    ['added', 'Stock Added'],
    ['consumed', 'Stock Consumed'],
    ['adjusted', 'Stock Adjusted']
  ].freeze

  # Reference type constants
  REFERENCE_TYPES = [
    ['vendor_purchase', 'Vendor Purchase'],
    ['booking', 'Booking'],
    ['adjustment', 'Manual Adjustment']
  ].freeze

  belongs_to :product

  validates :reference_type, presence: true, inclusion: { in: REFERENCE_TYPES.map(&:first) }
  validates :movement_type, presence: true, inclusion: { in: MOVEMENT_TYPES.map(&:first) }
  validates :quantity, presence: true, numericality: { not_equal_to: 0 }
  validates :stock_before, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_after, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reference_id, presence: true, if: -> { reference_type.in?(['vendor_purchase', 'booking']) }

  # Validation to ensure quantity direction matches movement type
  validate :validate_quantity_direction

  scope :recent, -> { order(created_at: :desc) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_movement_type, ->(type) { where(movement_type: type) }
  scope :by_reference_type, ->(type) { where(reference_type: type) }
  scope :additions, -> { where(movement_type: 'added') }
  scope :consumptions, -> { where(movement_type: 'consumed') }
  scope :adjustments, -> { where(movement_type: 'adjusted') }
  scope :from_bookings, -> { where(reference_type: 'booking') }
  scope :from_purchases, -> { where(reference_type: 'vendor_purchase') }
  scope :from_adjustments, -> { where(reference_type: 'adjustment') }

  # Get the reference object
  def reference_object
    case reference_type
    when 'vendor_purchase'
      VendorPurchase.find_by(id: reference_id)
    when 'booking'
      Booking.find_by(id: reference_id)
    else
      nil
    end
  end

  # Get reference description
  def reference_description
    case reference_type
    when 'vendor_purchase'
      purchase = reference_object
      purchase ? "Purchase ##{purchase.purchase_number}" : "Purchase ##{reference_id}"
    when 'booking'
      booking = reference_object
      booking ? "Booking ##{booking.booking_number}" : "Booking ##{reference_id}"
    when 'adjustment'
      'Manual Adjustment'
    else
      reference_type.humanize
    end
  end

  # Get formatted quantity with direction
  def formatted_quantity
    sign = quantity > 0 ? '+' : ''
    "#{sign}#{quantity}"
  end

  # Get movement type badge class
  def movement_type_badge_class
    case movement_type
    when 'added'
      'bg-success-subtle text-success'
    when 'consumed'
      'bg-danger-subtle text-danger'
    when 'adjusted'
      'bg-warning-subtle text-warning'
    else
      'bg-secondary-subtle text-secondary'
    end
  end

  # Get movement type icon
  def movement_type_icon
    case movement_type
    when 'added'
      'bi-plus-circle'
    when 'consumed'
      'bi-dash-circle'
    when 'adjusted'
      'bi-arrow-clockwise'
    else
      'bi-circle'
    end
  end

  private

  def validate_quantity_direction
    case movement_type
    when 'added'
      errors.add(:quantity, 'must be positive for stock additions') if quantity <= 0
    when 'consumed'
      errors.add(:quantity, 'must be negative for stock consumption') if quantity >= 0
    when 'adjusted'
      # Adjustments can be positive or negative
    end
  end
end