class WalletTransaction < ApplicationRecord
  belongs_to :customer_wallet

  validates :transaction_type, presence: true, inclusion: { in: %w[credit debit] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :balance_after, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :credits, -> { where(transaction_type: 'credit') }
  scope :debits, -> { where(transaction_type: 'debit') }
  scope :recent, -> { order(created_at: :desc) }

  def credit?
    transaction_type == 'credit'
  end

  def debit?
    transaction_type == 'debit'
  end

  def formatted_amount
    "₹#{amount.to_f.round(2)}"
  end

  def transaction_icon
    credit? ? 'plus-circle' : 'dash-circle'
  end

  def transaction_color
    credit? ? 'success' : 'danger'
  end
end
