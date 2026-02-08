class BookingItem < ApplicationRecord
  belongs_to :booking, counter_cache: true
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :check_stock_availability

  before_save :calculate_total
  after_create :reduce_product_stock
  after_update :handle_quantity_change, if: :saved_change_to_quantity?
  after_destroy :restore_product_stock

  def calculate_total
    self.total = quantity * price
  end

  private

  def check_stock_availability
    return unless quantity.present? && product.present?

    available_stock = product.stock

    # If this is an update, add back the previous quantity to available stock
    if persisted? && quantity_changed?
      available_stock += quantity_was
    end

    if quantity > available_stock
      errors.add(:quantity, "only #{available_stock} units available in stock")
    end
  end

  def reduce_product_stock
    return unless quantity.present? && product.present?

    product.decrement!(:stock, quantity)
    Rails.logger.info "Reduced stock for Product ##{product.id} by #{quantity}. New stock: #{product.reload.stock}"
  end

  def handle_quantity_change
    return unless quantity_previously_changed? && product.present?

    old_quantity = quantity_previously_was || 0
    new_quantity = quantity
    quantity_difference = new_quantity - old_quantity

    if quantity_difference > 0
      # Quantity increased, reduce more stock
      product.decrement!(:stock, quantity_difference)
      Rails.logger.info "Reduced additional stock for Product ##{product.id} by #{quantity_difference}. New stock: #{product.reload.stock}"
    elsif quantity_difference < 0
      # Quantity decreased, restore some stock
      product.increment!(:stock, quantity_difference.abs)
      Rails.logger.info "Restored stock for Product ##{product.id} by #{quantity_difference.abs}. New stock: #{product.reload.stock}"
    end
  end

  def restore_product_stock
    return unless quantity.present? && product.present?

    product.increment!(:stock, quantity)
    Rails.logger.info "Restored stock for Product ##{product.id} by #{quantity}. New stock: #{product.reload.stock}"
  end
end
