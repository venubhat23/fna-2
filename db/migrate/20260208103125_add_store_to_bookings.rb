class AddStoreToBookings < ActiveRecord::Migration[8.0]
  def change
    add_reference :bookings, :store, null: true, foreign_key: true, index: true
  end
end
