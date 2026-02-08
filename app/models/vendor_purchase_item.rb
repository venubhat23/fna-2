class VendorPurchaseItem < ApplicationRecord
  belongs_to :vendor_purchase
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :purchase_price, presence: true, numericality: { greater_than: 0 }
  validates :selling_price, presence: true, numericality: { greater_than: 0 }

  before_save :calculate_line_total
  validate :selling_price_should_be_greater_than_purchase_price

  def profit_margin
    return 0 if purchase_price.zero?
    ((selling_price - purchase_price) / purchase_price * 100).round(2)
  end

  def total_profit_potential
    (selling_price - purchase_price) * quantity
  end

  private

  def calculate_line_total
    self.line_total = quantity * purchase_price
  end

  def selling_price_should_be_greater_than_purchase_price
    return unless selling_price && purchase_price

    if selling_price <= purchase_price
      errors.add(:selling_price, 'must be greater than purchase price')
    end
  end
end