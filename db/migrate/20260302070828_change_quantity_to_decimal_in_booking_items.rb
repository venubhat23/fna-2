class ChangeQuantityToDecimalInBookingItems < ActiveRecord::Migration[8.0]
  def change
    change_column :booking_items, :quantity, :decimal, precision: 8, scale: 2
  end
end
