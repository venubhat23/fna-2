class AddBookingScheduleToBookings < ActiveRecord::Migration[8.0]
  def change
    add_reference :bookings, :booking_schedule, null: true, foreign_key: true
  end
end
