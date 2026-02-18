class CreateCustomerWallets < ActiveRecord::Migration[7.0]
  def change
    create_table :customer_wallets do |t|
      t.references :customer, null: false, foreign_key: true, index: { unique: true }
      t.decimal :balance, precision: 10, scale: 2, default: 0.0
      t.boolean :status, default: true
      t.text :notes

      t.timestamps
    end
  end
end
