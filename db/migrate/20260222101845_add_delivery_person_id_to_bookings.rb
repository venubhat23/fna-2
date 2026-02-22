class AddDeliveryPersonIdToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :delivery_person_id, :integer, null: true
    add_index :bookings, :delivery_person_id
  end
end
