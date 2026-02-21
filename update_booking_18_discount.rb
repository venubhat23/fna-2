# Check and update booking #18 with discount
booking = Booking.find(18) rescue nil

if booking
  puts 'Booking #18 Current Details:'
  puts "  Booking Number: #{booking.booking_number}"
  puts "  Total Amount: ₹#{booking.total_amount}"
  puts "  Discount Amount: ₹#{booking.discount_amount || 0}"
  puts "  Final Amount After Discount: ₹#{booking.final_amount_after_discount}"
  puts "  Calculated Subtotal: ₹#{booking.calculated_subtotal}"
  puts "  Calculated Total: ₹#{booking.calculated_total_amount}"

  if booking.discount_amount.present? && booking.discount_amount.to_f > 0
    puts '✅ Discount is already present'
  else
    puts '📝 Adding discount of ₹50 to booking #18...'
    booking.discount_amount = 50.0
    booking.save!
    booking.reload

    puts '✅ Updated booking details:'
    puts "  New Total Amount: ₹#{booking.total_amount}"
    puts "  New Discount Amount: ₹#{booking.discount_amount}"
    puts "  New Final Amount After Discount: ₹#{booking.final_amount_after_discount}"
    puts '✅ Discount will now show on the invoice!'
  end

  puts "\n🔗 Refresh the invoice: http://localhost:3000/admin/bookings/18/invoice"
else
  puts 'Booking #18 not found'
end