class CreateVendorPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :vendor_purchases do |t|
      t.references :vendor, null: false, foreign_key: true
      t.date :purchase_date
      t.decimal :total_amount
      t.decimal :paid_amount
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
