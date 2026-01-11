#!/usr/bin/env ruby

puts "🚀 Price Tracking System Demo"
puts "="*50

# Test price tracking functionality
product = Product.first

if product
  puts "\n📱 Product: #{product.name}"
  puts "💰 Current Price: #{product.formatted_today_price}"
  puts "📊 Yesterday Price: #{product.formatted_yesterday_price}"
  puts "📈 Price Change: #{product.formatted_price_change} (#{product.price_change_percentage_formatted})"
  puts "🔄 Trend: #{product.price_trend.humanize}"
  puts "📅 Last Updated: #{product.last_price_update&.strftime('%Y-%m-%d %H:%M') || 'Never'}"
  puts "📋 History Entries: #{product.get_price_history_array.length}"

  puts "\n📈 Price History (Last 7 Days):"
  product.get_price_history_array.each do |entry|
    date = Date.parse(entry['date'])
    price = "₹#{entry['price']}"
    simulated = entry['simulated'] ? " (simulated)" : ""
    puts "  #{date.strftime('%a %d %b')}: #{price}#{simulated}"
  end

  puts "\n🎯 Price Chart Features:"
  puts "  ✅ Real-time price tracking"
  puts "  ✅ Price change percentage calculation"
  puts "  ✅ Visual trend indicators"
  puts "  ✅ Interactive price chart"
  puts "  ✅ Price insights and alerts"
  puts "  ✅ Historical price data (30 days)"

  puts "\n🛠️ Available Rake Tasks:"
  puts "  rails price_tracking:update_daily_prices     # Update daily prices"
  puts "  rails price_tracking:initialize_tracking     # Initialize tracking"
  puts "  rails price_tracking:simulate_price_changes  # Simulate price changes"
  puts "  rails price_tracking:generate_sample_history # Generate sample data"
  puts "  rails price_tracking:cleanup_history         # Clean old data"

else
  puts "\n❌ No products found. Please add some products first."
end

puts "\n" + "="*50
puts "🎉 Price Tracking System is ready to use!"
puts "📍 Visit: http://localhost:3000/admin/products/1/detail to see it in action"
puts "="*50