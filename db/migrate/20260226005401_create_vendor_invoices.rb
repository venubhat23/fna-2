class CreateVendorInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :vendor_invoices do |t|
      t.references :vendor_purchase, null: false, foreign_key: true
      t.string :invoice_number
      t.decimal :total_amount
      t.integer :status
      t.date :invoice_date
      t.string :share_token
      t.text :notes

      t.timestamps
    end
    add_index :vendor_invoices, :invoice_number, unique: true
    add_index :vendor_invoices, :share_token, unique: true
  end
end
