class CreateVendorPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :vendor_payments do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :vendor_purchase, null: false, foreign_key: true
      t.decimal :amount_paid
      t.date :payment_date
      t.string :payment_mode
      t.text :notes

      t.timestamps
    end
  end
end
