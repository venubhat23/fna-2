class VendorPurchase < ApplicationRecord
  belongs_to :vendor
  has_many :vendor_purchase_items, dependent: :destroy
  has_many :products, through: :vendor_purchase_items
  has_many :stock_batches, dependent: :destroy
  has_many :vendor_payments, dependent: :destroy

  validates :purchase_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[pending completed cancelled] }

  accepts_nested_attributes_for :vendor_purchase_items, reject_if: :all_blank, allow_destroy: true

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
      'badge-success'
    when 'partial'
      'badge-warning'
    when 'unpaid'
      'badge-danger'
    end
  end

  def status_badge_class
    case status
    when 'completed'
      'badge-success'
    when 'pending'
      'badge-warning'
    when 'cancelled'
      'badge-danger'
    end
  end

  def can_be_cancelled?
    status == 'pending'
  end

  def can_be_edited?
    status == 'pending'
  end

  private

  def calculate_totals
    # Calculate total from items (both saved and unsaved)
    total = 0

    # Include both persisted and new items
    all_items = vendor_purchase_items.to_a

    all_items.each do |item|
      if item.quantity.present? && item.purchase_price.present?
        line_total = item.quantity * item.purchase_price
        total += line_total
      end
    end

    self.total_amount = total
    self.paid_amount ||= 0
  end

  def create_stock_batches
    vendor_purchase_items.each do |item|
      StockBatch.create!(
        product: item.product,
        vendor: vendor,
        vendor_purchase: self,
        quantity_purchased: item.quantity,
        quantity_remaining: item.quantity,
        purchase_price: item.purchase_price,
        selling_price: item.selling_price,
        batch_date: purchase_date,
        status: 'active'
      )
    end
  end

  def update_stock_batches
    # Update existing batches when purchase items are modified
    vendor_purchase_items.each do |item|
      batch = stock_batches.find_by(product: item.product)
      if batch
        batch.update!(
          quantity_purchased: item.quantity,
          quantity_remaining: item.quantity,
          purchase_price: item.purchase_price,
          selling_price: item.selling_price
        )
      end
    end
  end

  def saved_change_to_vendor_purchase_items?
    vendor_purchase_items.any?(&:changed?)
  end
end