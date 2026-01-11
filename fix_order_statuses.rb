#!/usr/bin/env ruby

puts 'Finding all orders and checking status:'
all_orders = Order.all
puts "Total orders: #{all_orders.count}"

all_orders.each do |order|
  if order.status.nil? || order.status.blank?
    puts "Updating order: #{order.order_number} from nil to pending"
    order.status = :pending
    if order.save
      puts "Successfully updated: #{order.order_number}"
    else
      puts "Failed to update: #{order.order_number} - #{order.errors.full_messages.join(', ')}"
    end
  else
    puts "Order #{order.order_number} already has status: #{order.status}"
  end
end

puts 'Final verification:'
Order.all.each do |order|
  can_show = !order.status.nil? && order.status != 'cancelled' && order.status != 'delivered'
  puts "Order #{order.order_number}: #{order.status} (can show buttons?: #{can_show})"
end