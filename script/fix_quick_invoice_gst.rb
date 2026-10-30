# Quick invoices used to store pre-GST prices, so their totals came out below
# what was charged. Rewrites them from the booking's GST-inclusive item prices.
#
# Preview: bin/rails runner script/fix_quick_invoice_gst.rb
# Apply:   APPLY=1 bin/rails runner script/fix_quick_invoice_gst.rb
apply = ENV['APPLY'] == '1'
changed = skipped = 0

Invoice.where(quick_invoice: true).includes(invoice_items: :product).find_each do |invoice|
  booking = Booking.includes(:booking_items).find_by(invoice_number: invoice.invoice_number)
  unless booking
    puts "SKIP #{invoice.invoice_number}: no booking found"
    skipped += 1
    next
  end

  remaining = booking.booking_items.to_a
  prices = invoice.invoice_items.map do |invoice_item|
    match = remaining.find { |i| i.product_id == invoice_item.product_id && i.quantity == invoice_item.quantity }
    remaining.delete_at(remaining.index(match)) if match
    [invoice_item, match && booking.invoice_unit_price_for(match)]
  end

  if prices.empty? || prices.any? { |_, price| price.nil? } || remaining.any?
    puts "SKIP #{invoice.invoice_number}: items do not match booking #{booking.booking_number}"
    skipped += 1
    next
  end

  new_total = prices.sum { |item, price| item.quantity * price }.round(2)
  new_paid = invoice.fully_paid? ? new_total : invoice.paid_amount
  next if (new_total - invoice.total_amount.to_f).abs < 0.01 && new_paid.to_f == invoice.paid_amount.to_f

  puts "#{invoice.invoice_number} (id #{invoice.id}): total #{invoice.total_amount.to_f} -> #{new_total.to_f}, paid #{invoice.paid_amount.to_f} -> #{new_paid.to_f}"
  changed += 1
  next unless apply

  Invoice.transaction do
    prices.each do |item, price|
      item.update_columns(unit_price: price.round(2), total_amount: (item.quantity * price).round(2))
    end
    invoice.update_columns(total_amount: new_total, paid_amount: new_paid)
  end
end

puts "#{apply ? 'Updated' : 'Would update'} #{changed} invoice(s), skipped #{skipped}."
