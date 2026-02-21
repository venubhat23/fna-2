# Add final_amount_after_discount column and update existing bookings
puts 'Adding final_amount_after_discount column to bookings table...'

begin
  # Check if column exists
  if !ActiveRecord::Base.connection.column_exists?(:bookings, :final_amount_after_discount)
    ActiveRecord::Base.connection.add_column :bookings, :final_amount_after_discount, :decimal, precision: 10, scale: 2
    puts '✅ Added final_amount_after_discount column to bookings table'
  else
    puts '✅ Column final_amount_after_discount already exists'
  end

  # Update existing bookings to calculate final_amount_after_discount
  updated_count = 0
  Booking.find_each do |booking|
    discount_amount = booking.discount_amount || 0
    total_amount = booking.total_amount || 0
    final_amount = total_amount - discount_amount

    booking.update_column(:final_amount_after_discount, final_amount)
    updated_count += 1
  end

  puts "Updated #{updated_count} existing bookings with calculated final amounts"

  # Show sample data
  puts "\nSample updated booking data:"
  sample_booking = Booking.first
  if sample_booking
    puts "Booking ID: #{sample_booking.id}"
    puts "Total Amount: ₹#{sample_booking.total_amount}"
    puts "Discount Amount: ₹#{sample_booking.discount_amount || 0}"
    puts "Final Amount After Discount: ₹#{sample_booking.final_amount_after_discount}"
  end

rescue => e
  puts "Error: #{e.message}"
end