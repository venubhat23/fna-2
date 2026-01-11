#!/usr/bin/env ruby

puts '🔄 Setting all products to active status...'
puts '=' * 45

updated_count = 0
error_count = 0

Product.all.each do |product|
  begin
    if product.status.nil?
      product.update!(status: :active)
      puts "✅ Updated #{product.name} to active status"
      updated_count += 1
    else
      puts "ℹ️  #{product.name} already has status: #{product.status}"
    end
  rescue => e
    puts "❌ Error updating #{product.name}: #{e.message}"
    error_count += 1
  end
end

puts "\n📊 Update Summary:"
puts "Successfully updated: #{updated_count} products"
puts "Already had status: #{Product.count - updated_count - error_count} products"
puts "Errors: #{error_count} products"

puts "\n📈 Final Status Distribution:"
Product.group(:status).count.each do |status, count|
  puts "  #{status}: #{count} products"
end

puts "\n✅ Now checking active products count: #{Product.active.count}"
puts "\n🎉 Product status update completed!"