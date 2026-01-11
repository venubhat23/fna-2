class AddStageToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :stage, :string
  end
end
