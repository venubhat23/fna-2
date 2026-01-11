class UpdateBookingPendingToOrderedAndDeliveryPending < ActiveRecord::Migration[8.0]
  def up
    # Update existing bookings with 'pending' status (value 1) to 'ordered_and_delivery_pending' (value 1)
    # Since both use the same integer value (1), we don't need to change the data for bookings
    puts "✅ Booking status enum updated: 'pending' is now 'ordered_and_delivery_pending'"

    # Orders also use integer enums now, so no need to update the data
    # The integer value 1 now maps to 'ordered_and_delivery_pending' instead of 'pending'
    puts "✅ Order status enum updated: 'pending' is now 'ordered_and_delivery_pending'"
  end

  def down
    # Since we're only changing the enum mapping and not the actual integer values,
    # nothing needs to be done for rollback
    puts "✅ Status enums reverted"
  end
end
