class CreateBookingItems < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_items do |t|
      t.integer :booking_id
      t.integer :product_id
      t.integer :quantity
      t.decimal :price
      t.decimal :total

      t.timestamps
    end
  end
end
