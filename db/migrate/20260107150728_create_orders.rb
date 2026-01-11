class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.integer :booking_id
      t.integer :customer_id
      t.integer :user_id
      t.string :order_number
      t.datetime :order_date
      t.string :status
      t.string :payment_method
      t.string :payment_status
      t.decimal :subtotal
      t.decimal :tax_amount
      t.decimal :discount_amount
      t.decimal :shipping_amount
      t.decimal :total_amount
      t.text :notes
      t.text :order_items
      t.string :customer_name
      t.string :customer_email
      t.string :customer_phone
      t.text :delivery_address
      t.string :tracking_number
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
