class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.integer :customer_id
      t.integer :user_id
      t.string :booking_number
      t.datetime :booking_date
      t.string :status
      t.string :payment_method
      t.string :payment_status
      t.decimal :subtotal
      t.decimal :tax_amount
      t.decimal :discount_amount
      t.decimal :total_amount
      t.text :notes
      t.text :booking_items
      t.string :customer_name
      t.string :customer_email
      t.string :customer_phone
      t.text :delivery_address
      t.boolean :invoice_generated
      t.string :invoice_number
      t.decimal :cash_received
      t.decimal :change_amount

      t.timestamps
    end
  end
end
