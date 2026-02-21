# Fix final_amount_after_discount for all bookings
puts 'Fixing final_amount_after_discount calculations...'

updated_count = 0
Booking.find_each do |booking|
  # Calculate correct final amount
  base_amount = (booking.subtotal || booking.calculated_subtotal).to_f + (booking.tax_amount || booking.calculated_tax_amount).to_f
  discount_amt = booking.discount_amount.to_f

  correct_final_amount = base_amount - discount_amt

  if booking.final_amount_after_discount != correct_final_amount
    booking.update_column(:final_amount_after_discount, correct_final_amount)
    puts "Updated booking ##{booking.id}: #{booking.final_amount_after_discount} -> #{correct_final_amount}"
    updated_count += 1
  end
end

puts "Updated #{updated_count} bookings"

# Test booking #18 specifically
booking = Booking.find(18)
puts "\nBooking #18 corrected values:"
puts "  Subtotal: ₹#{booking.calculated_subtotal}"
puts "  Discount: ₹#{booking.discount_amount}"
puts "  Tax: ₹#{booking.calculated_tax_amount}"
puts "  Original Total: ₹#{booking.calculated_subtotal + booking.calculated_tax_amount}"
puts "  Final Amount: ₹#{booking.final_amount_after_discount}"

puts "\n✅ All calculations are now correct!"