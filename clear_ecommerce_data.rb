#!/usr/bin/env ruby

# Clear Ecommerce Data Script
# This script removes all products, bookings, and invoice data from the database
puts "🧹 Starting Ecommerce Data Cleanup..."
puts "=" * 50

# Track what we're clearing
models_to_clear = [
  'BookingInvoice',
  'BookingItem',
  'Booking',
  'OrderItem',
  'Order',
  'ProductReview',
  'ProductRating',
  'DeliveryRule',
  'Product',
  'Category',
  'Coupon',
  'DeliveryPerson',
  'Franchise'
]

# Store counts before deletion
counts_before = {}
models_to_clear.each do |model|
  begin
    klass = model.constantize
    count = klass.count
    counts_before[model] = count
    puts "📊 #{model}: #{count} records"
  rescue NameError
    puts "⚠️  #{model}: Model not found, skipping..."
    counts_before[model] = 0
  end
end

puts "\n🗑️  Starting deletion process..."
puts "-" * 30

# Clear data in proper order (respecting foreign key constraints)
deletion_order = [
  'BookingInvoice',  # First, clear invoices (depends on bookings)
  'BookingItem',     # Then booking items (depends on bookings & products)
  'OrderItem',       # Order items (depends on orders & products)
  'Order',           # Orders (depends on bookings)
  'Booking',         # Bookings
  'ProductReview',   # Product reviews (depends on products)
  'ProductRating',   # Product ratings (depends on products)
  'DeliveryRule',    # Delivery rules (depends on products)
  'Product',         # Products (depends on categories)
  'Category',        # Categories
  'Coupon',          # Coupons (standalone)
  'DeliveryPerson',  # Delivery people (standalone)
  'Franchise'        # Franchises (standalone)
]

deleted_counts = {}

deletion_order.each do |model|
  begin
    klass = model.constantize
    initial_count = klass.count

    if initial_count > 0
      puts "🗑️  Clearing #{model}..."

      # For models with attached files, we need special handling
      if model == 'Product'
        # Clear attached images first
        puts "   📸 Clearing product images..."
        klass.all.each do |product|
          product.images.purge if product.respond_to?(:images)
        end
      end

      # Delete all records
      klass.delete_all
      final_count = klass.count
      deleted_counts[model] = initial_count - final_count

      puts "   ✅ Cleared #{deleted_counts[model]} #{model} records"
    else
      puts "   ℹ️  #{model}: No records to clear"
      deleted_counts[model] = 0
    end
  rescue NameError
    puts "   ⚠️  #{model}: Model not found, skipping..."
    deleted_counts[model] = 0
  rescue => e
    puts "   ❌ Error clearing #{model}: #{e.message}"
    deleted_counts[model] = 0
  end
end

puts "\n📊 Cleanup Summary:"
puts "=" * 50

total_deleted = 0
deletion_order.each do |model|
  before_count = counts_before[model] || 0
  deleted_count = deleted_counts[model] || 0

  if deleted_count > 0
    puts "✅ #{model.ljust(20)} | #{before_count.to_s.rjust(6)} → #{(before_count - deleted_count).to_s.rjust(6)} | Deleted: #{deleted_count}"
    total_deleted += deleted_count
  else
    puts "ℹ️  #{model.ljust(20)} | #{before_count.to_s.rjust(6)} → #{before_count.to_s.rjust(6)} | No changes"
  end
end

puts "-" * 50
puts "🎉 Total records deleted: #{total_deleted}"

# Reset auto-increment counters (PostgreSQL)
if ActiveRecord::Base.connection.adapter_name.downcase.include?('postgresql')
  puts "\n🔄 Resetting auto-increment sequences..."

  tables_to_reset = %w[
    booking_invoices bookings booking_items orders order_items
    products categories product_reviews product_ratings
    delivery_rules coupons delivery_people franchises
  ]

  tables_to_reset.each do |table|
    begin
      ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{table}_id_seq RESTART WITH 1;")
      puts "   ✅ Reset #{table} sequence"
    rescue => e
      puts "   ⚠️  Could not reset #{table} sequence: #{e.message}"
    end
  end
end

puts "\n🧹 Ecommerce data cleanup completed successfully!"
puts "💡 You can now start fresh with your ecommerce data."
puts "=" * 50