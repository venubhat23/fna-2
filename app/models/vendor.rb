class Vendor < ApplicationRecord
  has_many :vendor_purchases, dependent: :destroy
  has_many :stock_batches, dependent: :destroy
  has_many :vendor_payments, through: :vendor_purchases

  validates :name, presence: true
  validates :payment_type, inclusion: { in: %w[Cash Credit] }
  validates :status, inclusion: { in: [true, false] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :opening_balance, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }

  def total_purchases
    vendor_purchases.sum(:total_amount)
  end

  def total_paid
    vendor_purchases.sum(:paid_amount)
  end

  def outstanding_balance
    total_purchases - total_paid + (opening_balance || 0)
  end

  def can_be_deleted?
    vendor_purchases.empty?
  end

  def display_name
    name
  end

  def payment_type_badge_class
    case payment_type
    when 'Cash'
      'badge-success'
    when 'Credit'
      'badge-warning'
    else
      'badge-secondary'
    end
  end

  def status_badge_class
    status ? 'badge-success' : 'badge-danger'
  end

  def status_text
    status ? 'Active' : 'Inactive'
  end
end