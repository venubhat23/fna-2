class CreateBookingSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_schedules do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :schedule_type
      t.string :frequency
      t.date :start_date
      t.date :end_date
      t.integer :quantity
      t.time :delivery_time
      t.text :delivery_address
      t.string :pincode
      t.decimal :latitude
      t.decimal :longitude
      t.string :status
      t.date :next_booking_date
      t.integer :total_bookings_generated
      t.text :notes

      t.timestamps
    end
  end
end
