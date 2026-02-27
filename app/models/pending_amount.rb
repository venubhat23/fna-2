class PendingAmount < ApplicationRecord
  belongs_to :customer

  enum status: {
    pending: 0,
    resolved: 1,
    cancelled: 2
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  validates :pending_date, presence: true
  validates :status, presence: true

  scope :for_last_month, -> { where(pending_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }
  scope :current_pending, -> { where(status: :pending) }

  def display_amount
    "₹#{amount.to_f.round(2)}"
  end

  def formatted_pending_date
    pending_date&.strftime("%d %b %Y")
  end
end
