class PendingAmount < ApplicationRecord
  belongs_to :customer

  # Fixed enum syntax for Rails 8 compatibility
  enum :status, {
    pending: 0,
    resolved: 1,
    cancelled: 2
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  validates :pending_date, presence: true
  validates :status, presence: true

  scope :for_last_month, -> { where(pending_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }
  scope :from_last_month_to_today, -> { where(pending_date: 1.month.ago.beginning_of_month..Date.current) }
  scope :current_pending, -> { where(status: :pending) }

  def display_amount
    "₹#{amount.to_f.round(2)}"
  end

  def formatted_pending_date
    pending_date&.strftime("%d %b %Y")
  end
end
