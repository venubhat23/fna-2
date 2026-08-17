class DeliveryCharge < ApplicationRecord
  validates :pincode, presence: true, uniqueness: true
  validates :charge_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  def self.for_pincode(pincode)
    find_by(pincode: pincode, is_active: true)
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
