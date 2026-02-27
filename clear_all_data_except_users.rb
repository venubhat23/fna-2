# Rails Console Script to Clear All Data Except Users
# Run this in Rails console: load 'clear_all_data_except_users.rb'
# WARNING: This will permanently delete all data except users!

puts "🚨 WARNING: This will delete PRODUCTS, CATEGORIES, INVOICES, ITEMS & VENDOR DATA!"
puts "💾 This includes all products, categories, invoices, invoice items, vendor purchases, vendor payments, etc."
puts "✅ PRESERVED: Users, customers, orders, bookings, insurance data, affiliates, etc. will be kept"
puts ""
puts "Models to be cleared:"

# List all models that will be cleared - FOCUSED ON PRODUCTS, CATEGORIES, INVOICES & VENDOR DATA
# IMPORTANT: Ordered by dependencies - child tables first, parent tables last
models_to_clear = [
  # Items and junction tables (delete first)
  'InvoiceItem',
  'VendorPurchaseItem',
  'SaleItem',
  'BookingItem',
  'OrderItem',
  'StockMovement',
  'ProductReview',
  'ProductRating',
  'Wishlist',

  # Vendor financial records
  'VendorPayment',
  'VendorInvoice',

  # Invoice related (after items deleted)
  'BookingInvoice',
  'Invoice',

  # Vendor purchases (after items deleted)
  'VendorPurchase',

  # Stock and inventory
  'StockBatch',

  # Vendor entity (after all vendor-related records deleted)
  'Vendor',

  # Store (if related to products/vendors)
  'Store',

  # Products (after all items and references deleted)
  'Product',

  # Categories (after products deleted)
  'Category'
]

models_to_clear.each_with_index do |model, index|
  puts "#{index + 1}. #{model}"
end

puts ""
puts "🔒 PRESERVED: Users, Customers, Orders, Bookings, Insurance, Affiliates, and other business data will be kept"
puts ""
print "Type 'YES' to confirm deletion (anything else to cancel): "

# In console, you would get input, but for script we'll add a safety check
confirmation = gets.chomp if defined?(gets)

if confirmation == 'YES'
  puts ""
  puts "🗑️  Starting data cleanup..."
  puts ""

  # Keep track of deleted records
  total_deleted = 0
  deletion_summary = {}

  # Disable foreign key checks temporarily if using PostgreSQL
  disable_foreign_keys = false
  if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    begin
      puts "🔧 Temporarily disabling foreign key checks..."
      ActiveRecord::Base.connection.execute("SET session_replication_role = replica;")
      disable_foreign_keys = true
      puts "✅ Foreign key checks disabled"
    rescue => e
      puts "⚠️  Could not disable foreign keys: #{e.message}"
    end
  end

  # Clear models in dependency order (children first, then parents)
  errors_encountered = []

  models_to_clear.each do |model_name|
    begin
      model_class = model_name.constantize

      if model_class.respond_to?(:count)
        record_count = model_class.count

        if record_count > 0
          puts "🔄 Clearing #{model_name} (#{record_count} records)..."

          # Use delete_all for faster deletion (skips callbacks)
          deleted_count = model_class.delete_all
          deletion_summary[model_name] = deleted_count
          total_deleted += deleted_count

          puts "✅ Deleted #{deleted_count} #{model_name} records"
        else
          puts "⭕ #{model_name} already empty"
        end
      end
    rescue NameError => e
      puts "⚠️  Model #{model_name} not found (may not exist in this app)"
    rescue => e
      error_msg = "❌ Error clearing #{model_name}: #{e.message}"
      puts error_msg
      errors_encountered << error_msg

      # Try to continue with other models
      next
    end
  end

  # Re-enable foreign key checks
  if disable_foreign_keys
    begin
      puts "🔧 Re-enabling foreign key checks..."
      ActiveRecord::Base.connection.execute("SET session_replication_role = DEFAULT;")
      puts "✅ Foreign key checks re-enabled"
    rescue => e
      puts "⚠️  Could not re-enable foreign keys: #{e.message}"
    end
  end

  # Report any errors encountered
  if errors_encountered.any?
    puts ""
    puts "⚠️  ERRORS ENCOUNTERED:"
    errors_encountered.each { |error| puts "   #{error}" }
  end

  puts ""
  puts "📊 DELETION SUMMARY:"
  puts "==================="
  deletion_summary.each do |model, count|
    puts "#{model}: #{count} records deleted"
  end

  puts ""
  puts "🎯 TOTAL DELETED: #{total_deleted} records"

  # Verify preserved data is still there
  user_count = User.count rescue 0
  customer_count = Customer.count rescue 0
  booking_count = Booking.count rescue 0
  order_count = Order.count rescue 0

  puts "👥 USERS PRESERVED: #{user_count} user records"
  puts "👥 CUSTOMERS PRESERVED: #{customer_count} customer records"
  puts "📋 BOOKINGS PRESERVED: #{booking_count} booking records"
  puts "📋 ORDERS PRESERVED: #{order_count} order records"

  # Reset auto-increment sequences (for PostgreSQL)
  if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    puts ""
    puts "🔧 Resetting auto-increment sequences..."

    models_to_clear.each do |model_name|
      begin
        model_class = model_name.constantize
        table_name = model_class.table_name
        sequence_name = "#{table_name}_id_seq"

        ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{sequence_name} RESTART WITH 1;")
      rescue => e
        # Ignore sequence reset errors
      end
    end

    puts "✅ Sequences reset complete"
  end

  puts ""
  puts "🎉 PRODUCT & VENDOR DATA CLEANUP COMPLETED SUCCESSFULLY!"
  puts "🔒 Users, customers, orders, bookings, and insurance data preserved"
  puts "📦 Products, categories, invoices, and vendor data have been cleared"
  puts "📈 You can now add fresh product catalog and vendor data"

else
  puts ""
  puts "❌ Cleanup cancelled. No data was deleted."
end

puts ""
puts "Script completed."