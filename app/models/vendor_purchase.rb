class VendorPurchase < ApplicationRecord
  belongs_to :vendor
  has_many :vendor_purchase_items, dependent: :destroy
  has_many :products, through: :vendor_purchase_items
  has_many :stock_batches, dependent: :destroy
  has_many :vendor_payments, dependent: :destroy
  has_one :vendor_invoice, dependent: :destroy

  validates :purchase_date, presence: true
  validates :paid_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :must_have_items
  validate :validate_total_amount
  validates :status, inclusion: { in: %w[pending completed cancelled] }

  accepts_nested_attributes_for :vendor_purchase_items, reject_if: lambda { |attrs| attrs['product_id'].blank? && attrs['quantity'].blank? }, allow_destroy: true

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :recent, -> { order(created_at: :desc) }

  before_save :calculate_totals
  after_save :create_stock_batches, if: :saved_change_to_id?
  after_update :update_stock_batches, if: :saved_change_to_vendor_purchase_items?

  def purchase_number
    "VP#{id.to_s.rjust(6, '0')}"
  end

  def outstanding_amount
    total_amount - paid_amount
  end

  def payment_status
    if paid_amount >= total_amount
      'paid'
    elsif paid_amount > 0
      'partial'
    else
      'unpaid'
    end
  end

  def payment_status_badge_class
    case payment_status
    when 'paid'
      'bg-success text-white border-0'
    when 'partial'
      'bg-warning text-dark border-0'
    when 'unpaid'
      'bg-danger text-white border-0'
    else
      'bg-secondary text-white border-0'
    end
  end

  def status_badge_class
    case status
    when 'completed'
      'bg-success text-white border-0'
    when 'pending'
      'bg-warning text-dark border-0'
    when 'cancelled'
      'bg-danger text-white border-0'
    else
      'bg-secondary text-white border-0'
    end
  end

  def can_be_cancelled?
    status == 'pending'
  end

  def can_be_edited?
    status == 'pending'
  end

  private

  def must_have_items
    if vendor_purchase_items.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "Purchase must have at least one item")
    end
  end

  def validate_total_amount
    # Calculate total manually for validation
    calculate_totals

    if total_amount.blank?
      errors.add(:total_amount, "can't be blank")
    elsif total_amount <= 0
      errors.add(:total_amount, "must be greater than 0. Please add at least one item.")
    end
  end

  def calculate_totals
    # Calculate total from items (both saved and unsaved)
    total = 0

    # Include both persisted and new items
    all_items = vendor_purchase_items.reject(&:marked_for_destruction?)

    all_items.each do |item|
      if item.quantity.present? && item.purchase_price.present?
        quantity = item.quantity.to_f
        price = item.purchase_price.to_f
        line_total = quantity * price
        total += line_total if line_total > 0
      end
    end

    self.total_amount = total
    self.paid_amount ||= 0
  end

  # Bulk-creates stock batches + stock movements in 2 INSERTs instead of one
  # round trip per item (previously: 2 SELECTs + 2 INSERTs per item, i.e. an
  # N+1 that made a 5-item purchase issue ~20 separate DB calls).
  def create_stock_batches
    items = vendor_purchase_items.to_a
    return if items.empty?

    products = Product.where(id: items.map(&:product_id)).index_by(&:id)
    current_stock_by_product = StockBatch.active
                                          .where(product_id: items.map(&:product_id))
                                          .group(:product_id).sum(:quantity_remaining)

    now = Time.current
    batch_rows = []
    movement_rows = []
    stock_by_product = {}

    items.each do |item|
      product = products[item.product_id]
      current_stock = (stock_by_product[item.product_id] ||= current_stock_by_product[item.product_id].to_f)
      new_stock = current_stock + item.quantity.to_f
      stock_by_product[item.product_id] = new_stock

      batch_rows << {
        product_id: item.product_id,
        vendor_id: vendor_id,
        vendor_purchase_id: id,
        quantity_purchased: item.quantity,
        quantity_remaining: item.quantity,
        purchase_price: item.purchase_price,
        selling_price: item.selling_price,
        batch_date: purchase_date,
        status: 'active',
        created_at: now,
        updated_at: now
      }

      movement_rows << {
        product_id: item.product_id,
        reference_type: 'vendor_purchase',
        reference_id: id,
        movement_type: 'added',
        quantity: item.quantity.to_f,
        stock_before: current_stock,
        stock_after: new_stock,
        notes: "Stock added from vendor purchase: #{purchase_number} - #{product.name} (Qty: #{item.quantity})",
        created_at: now,
        updated_at: now
      }
    end

    StockBatch.insert_all(batch_rows)
    StockMovement.insert_all(movement_rows)
    stock_by_product.each { |product_id, stock| Product.where(id: product_id).update_all(stock: stock) }
  end

  def update_stock_batches
    items = vendor_purchase_items.to_a
    return if items.empty?

    product_ids = items.map(&:product_id)
    products = Product.where(id: product_ids).index_by(&:id)
    existing_batches = stock_batches.where(product_id: product_ids).index_by(&:product_id)
    current_stock_by_product = StockBatch.active.where(product_id: product_ids)
                                          .group(:product_id).sum(:quantity_remaining)

    now = Time.current
    movement_rows = []
    stock_by_product = {}

    items.each do |item|
      batch = existing_batches[item.product_id]
      next unless batch

      product = products[item.product_id]
      current_stock = (stock_by_product[item.product_id] ||= current_stock_by_product[item.product_id].to_f)
      old_quantity = batch.quantity_purchased.to_f
      new_quantity = item.quantity.to_f
      quantity_difference = new_quantity - old_quantity

      batch.update!(
        quantity_purchased: item.quantity,
        quantity_remaining: item.quantity,
        purchase_price: item.purchase_price,
        selling_price: item.selling_price
      )

      new_stock = current_stock + quantity_difference
      stock_by_product[item.product_id] = new_stock

      next if quantity_difference == 0

      movement_rows << {
        product_id: item.product_id,
        reference_type: 'vendor_purchase',
        reference_id: id,
        movement_type: quantity_difference > 0 ? 'added' : 'adjusted',
        quantity: quantity_difference,
        stock_before: current_stock,
        stock_after: new_stock,
        notes: "Vendor purchase updated: #{purchase_number} - #{product.name} quantity changed by #{quantity_difference}",
        created_at: now,
        updated_at: now
      }
    end

    StockMovement.insert_all(movement_rows) if movement_rows.any?
    stock_by_product.each { |product_id, stock| Product.where(id: product_id).update_all(stock: stock) }
  end

  def saved_change_to_vendor_purchase_items?
    vendor_purchase_items.any?(&:changed?)
  end
end