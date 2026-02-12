class AddBookingIdToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :booking_id, :integer
    add_index :orders, :booking_id
  end
end
