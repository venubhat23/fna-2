class AddIsOutletBookingToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :is_outlet_booking, :boolean, default: true, null: false
  end
end
