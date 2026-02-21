# Check booking #17 specifically
booking = Booking.find(17) rescue nil

if booking
  puts 'Booking #17 Details:'
  puts "  ID: #{booking.id}"
  puts "  Booking Number: #{booking.booking_number}"
  puts "  Total Amount: ₹#{booking.total_amount}"
  puts "  Discount Amount: ₹#{booking.discount_amount || 0}"
  puts "  Final Amount After Discount: ₹#{booking.final_amount_after_discount}"

  # Check if discount is present
  if booking.discount_amount.present? && booking.discount_amount.to_f > 0
    puts '✅ Discount is present and should show on invoice'
  else
    puts '⚠️  No discount applied to this booking'

    # Add a test discount to demonstrate functionality
    puts "\n📝 Adding test discount of ₹25 to demonstrate..."
    booking.discount_amount = 25.0
    booking.save!
    booking.reload

    puts "  Updated Total Amount: ₹#{booking.total_amount}"
    puts "  Updated Discount Amount: ₹#{booking.discount_amount}"
    puts "  Updated Final Amount After Discount: ₹#{booking.final_amount_after_discount}"
    puts '✅ Now the discount will show on the invoice!'
  end

  puts "\n🔗 Invoice URL: http://localhost:3000/admin/bookings/#{booking.id}/invoice"
else
  puts 'Booking #17 not found'
  puts 'Available bookings:'
  Booking.limit(5).each do |b|
    puts "  - Booking ##{b.id}: #{b.booking_number}"
  end
end