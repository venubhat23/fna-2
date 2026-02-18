class Invoice < ApplicationRecord
  belongs_to :customer
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by', optional: true
  has_many :invoice_items, dependent: :destroy

  enum :status, { draft: 'draft', sent: 'sent', paid: 'paid', overdue: 'overdue', cancelled: 'cancelled' }
  enum :payment_status, { unpaid: 0, partially_paid: 1, fully_paid: 2 }

  validates :invoice_number, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :invoice_date, presence: true

  before_validation :generate_invoice_number, on: :create

  scope :for_month, ->(month, year) { where(invoice_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month) }

  private

  def generate_invoice_number
    return if invoice_number.present?

    last_invoice = Invoice.order(:created_at).last
    number = last_invoice ? last_invoice.invoice_number.split('-').last.to_i + 1 : 1
    self.invoice_number = "INV-#{Date.current.strftime('%Y%m')}-#{number.to_s.rjust(4, '0')}"
  end
end
