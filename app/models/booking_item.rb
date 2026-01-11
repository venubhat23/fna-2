class BookingItem < ApplicationRecord
  belongs_to :booking, counter_cache: true
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total

  def calculate_total
    self.total = quantity * price
  end
end
