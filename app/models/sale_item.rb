class SaleItem < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :booking, optional: true
  belongs_to :product
  belongs_to :stock_batch

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :selling_price, presence: true, numericality: { greater_than: 0 }
  validates :purchase_price, presence: true, numericality: { greater_than: 0 }

  before_save :calculate_profit_and_total

  def profit_per_unit
    selling_price - purchase_price
  end

  def profit_margin_percentage
    return 0 if purchase_price.zero?
    (profit_per_unit / purchase_price * 100).round(2)
  end

  def self.total_profit_for_period(start_date, end_date)
    joins(:order)
      .where(orders: { created_at: start_date..end_date })
      .sum(:profit_amount)
  end

  def self.profit_by_product(start_date, end_date)
    joins(:order, :product)
      .where(orders: { created_at: start_date..end_date })
      .group('products.name')
      .sum(:profit_amount)
  end

  def self.profit_by_vendor(start_date, end_date)
    joins(:order, stock_batch: :vendor)
      .where(orders: { created_at: start_date..end_date })
      .group('vendors.name')
      .sum(:profit_amount)
  end

  private

  def calculate_profit_and_total
    self.profit_amount = profit_per_unit * quantity
    self.line_total = selling_price * quantity
  end
end