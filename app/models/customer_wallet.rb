class CustomerWallet < ApplicationRecord
  belongs_to :customer
  has_many :wallet_transactions, dependent: :destroy

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :set_defaults

  def add_money(amount, description = nil, reference = nil)
    transaction do
      self.balance += amount
      save!

      wallet_transactions.create!(
        transaction_type: 'credit',
        amount: amount,
        balance_after: balance,
        description: description || 'Money added to wallet',
        reference_number: reference || generate_reference_number
      )
    end
  end

  def deduct_money(amount, description = nil, reference = nil)
    return false if balance < amount

    transaction do
      self.balance -= amount
      save!

      wallet_transactions.create!(
        transaction_type: 'debit',
        amount: amount,
        balance_after: balance,
        description: description || 'Money deducted from wallet',
        reference_number: reference || generate_reference_number
      )
    end

    true
  end

  def formatted_balance
    "₹#{balance.to_f.round(2)}"
  end

  private

  def set_defaults
    self.balance ||= 0.0
  end

  def generate_reference_number
    "TXN#{Time.current.to_i}#{rand(1000..9999)}"
  end
end
