class AddFinalAmountAfterDiscountToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :final_amount_after_discount, :decimal, precision: 10, scale: 2
  end
end
