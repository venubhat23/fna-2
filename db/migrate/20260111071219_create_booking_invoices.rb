class CreateBookingInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_invoices do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :customer, null: true, foreign_key: true
      t.string :invoice_number
      t.datetime :invoice_date
      t.datetime :due_date
      t.decimal :subtotal, precision: 10, scale: 2
      t.decimal :tax_amount, precision: 10, scale: 2
      t.decimal :discount_amount, precision: 10, scale: 2
      t.decimal :total_amount, precision: 10, scale: 2
      t.integer :payment_status
      t.integer :status
      t.text :notes
      t.text :invoice_items
      t.datetime :paid_at

      t.timestamps
    end
    add_index :booking_invoices, :invoice_number, unique: true
  end
end
