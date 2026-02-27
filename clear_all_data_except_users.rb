# Rails Console Script to Clear All Data Except Users
# Run this in Rails console: load 'clear_all_data_except_users.rb'
# WARNING: This will permanently delete all data except users!

puts "🚨 WARNING: This will delete ALL data except users!"
puts "💾 This includes all products, categories, orders, invoices, customers, etc."
puts ""
puts "Models to be cleared:"

# List all models that will be cleared
# IMPORTANT: Ordered by dependencies - child tables first, parent tables last
models_to_clear = [
  # Start with junction tables and items that reference other tables
  'BookingItem',
  'OrderItem',
  'InvoiceItem',
  'VendorPurchaseItem',
  'SaleItem',
  'StockMovement',
  'ProductReview',
  'ProductRating',
  'MilkDeliveryTask',
  'WalletTransaction',
  'DeviceToken',
  'Wishlist',
  'Notification',
  'CustomerAddress',
  'CustomerFormat',

  # Insurance member/nominee/document tables
  'HealthInsuranceMember',
  'LifeInsuranceNominee',
  'LifeInsuranceDocument',
  'LifeInsuranceBankDetail',

  # Document tables
  'CustomerDocument',
  'DistributorDocument',
  'SubAgentDocument',
  'InvestorDocument',

  # Financial records that reference other entities
  'CommissionPayout',
  'CommissionReceipt',
  'PayoutDistribution',
  'PayoutAuditLog',
  'VendorPayment',
  'DistributorPayout',

  # Business relationship tables
  'DistributorAssignment',
  'Referral',

  # Booking and order related (after items are deleted)
  'BookingInvoice',
  'BookingSchedule',
  'VendorInvoice',
  'Invoice',
  'Booking',
  'Order',
  'VendorPurchase',

  # Subscription related
  'MilkSubscription',
  'SubscriptionTemplate',

  # Insurance policies (after members/nominees deleted)
  'HealthInsurance',
  'LifeInsurance',
  'MotorInsurance',
  'OtherInsurance',

  # Financial entities
  'Payout',
  'Investment',
  'CustomerWallet',

  # Stock and inventory
  'StockBatch',

  # Business entities (after their related records deleted)
  'Lead',
  'ClientRequest',
  'TaxService',
  'Loan',
  'TravelPackage',

  # Network entities (after assignments/documents deleted)
  'SubAgent',
  'Investor',
  'Distributor',
  'Affiliate',
  'Franchise',

  # Core entities that are referenced by others
  'Customer',
  'DeliveryPerson',
  'Vendor',
  'Store',
  'Product',
  'Category',

  # System and config entities
  'InsuranceCompany',
  'AgencyCode',
  'AgencyBroker',
  'Broker',
  'Banner',
  'Coupon',
  'DeliveryRule',
  'Report',
  'Document',
  'FamilyMember',
  'CorporateMember',
  'Message',
  'SystemSetting'
]

models_to_clear.each_with_index do |model, index|
  puts "#{index + 1}. #{model}"
end

puts ""
puts "🔒 PRESERVED: User, Role, Permission, RolePermission, UserRole models will be kept"
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

  # Verify users are still there
  user_count = User.count rescue 0
  puts "👥 USERS PRESERVED: #{user_count} user records"

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
  puts "🎉 DATA CLEANUP COMPLETED SUCCESSFULLY!"
  puts "🔒 All user accounts have been preserved"
  puts "📈 You can now start fresh with clean data"

else
  puts ""
  puts "❌ Cleanup cancelled. No data was deleted."
end

puts ""
puts "Script completed."