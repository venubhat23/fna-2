class DeliveryCharge < ApplicationRecord
  before_validation { self.pincode = pincode.to_s.gsub(/[^0-9]/, '') }

  validates :pincode, presence: true, uniqueness: true, format: { with: /\A\d{6}\z/, message: 'must be a 6-digit pincode' }
  validates :charge_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  # Matches on digits-only rather than an exact DB string comparison so a
  # stray whitespace/invisible character on an already-stored pincode (which
  # renders identically to the clean value in the admin table, since HTML
  # collapses whitespace) doesn't silently make an otherwise-active zone
  # look unserviceable to the customer-facing lookup.
  def self.for_pincode(pincode)
    normalized = pincode.to_s.gsub(/[^0-9]/, '')
    return nil if normalized.blank?

    active.detect { |charge| charge.pincode.to_s.gsub(/[^0-9]/, '') == normalized }
  end

  def self.charge_for_pincode(pincode)
    charge = for_pincode(pincode)
    charge&.charge_amount || 0.0
  end

  # Returns the effective charge for a given order amount,
  # applying free delivery if allowed and threshold is met.
  def effective_charge_for(order_amount)
    return charge_amount.to_f unless free_delivery_allowed?
    order_amount.to_f >= min_order_for_free_delivery.to_f ? 0.0 : charge_amount.to_f
  end

  def formatted_charge
    "₹#{charge_amount}"
  end

  def free_delivery_threshold
    "₹#{min_order_for_free_delivery}"
  end

  def status_text
    is_active? ? 'Active' : 'Inactive'
  end
end
