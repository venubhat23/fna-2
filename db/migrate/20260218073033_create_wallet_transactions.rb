class CreateWalletTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :wallet_transactions do |t|
      t.references :customer_wallet, null: false, foreign_key: true
      t.string :transaction_type # credit or debit
      t.decimal :amount, precision: 10, scale: 2
      t.decimal :balance_after, precision: 10, scale: 2
      t.string :description
      t.string :reference_number
      t.json :metadata

      t.timestamps
    end

    add_index :wallet_transactions, :transaction_type
    add_index :wallet_transactions, :reference_number, unique: true
  end
end
