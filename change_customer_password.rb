#!/usr/bin/env ruby

# Customer Password Change Script
# Usage examples:
# 1. Change password for specific customer by email:
#    RAILS_ENV=development bundle exec rails runner change_customer_password.rb email "customer@example.com" "NewPassword123"
#
# 2. Change password for specific customer by mobile:
#    RAILS_ENV=development bundle exec rails runner change_customer_password.rb mobile "9876543210" "NewPassword123"
#
# 3. Change password for customer by ID:
#    RAILS_ENV=development bundle exec rails runner change_customer_password.rb id "5" "NewPassword123"
#
# 4. Reset all customer passwords to default:
#    RAILS_ENV=development bundle exec rails runner change_customer_password.rb reset_all "Ganesha@123"
#
# 5. Change password for multiple customers by providing a file with emails:
#    RAILS_ENV=development bundle exec rails runner change_customer_password.rb bulk_email "customers.txt" "NewPassword123"

def change_customer_password_by_email(email, new_password)
  puts "🔍 Looking for customer with email: #{email}"

  # Find customer
  customer = Customer.find_by(email: email)
  unless customer
    puts "❌ Customer not found with email: #{email}"
    return false
  end

  # Find or create user account
  user = User.find_by(email: email)
  unless user
    puts "👤 Creating new user account for customer: #{customer.display_name}"

    # Get customer role
    customer_role = Role.find_by(name: 'customer') || Role.find_by(name: 'Customer')

    user = User.new(
      first_name: customer.first_name || 'Customer',
      last_name: customer.last_name || 'User',
      email: customer.email,
      password: new_password,
      password_confirmation: new_password,
      mobile: customer.mobile,
      user_type: 'customer',
      role: 'customer',
      role_id: customer_role&.id,
      status: true
    )

    if user.save(validate: false)
      puts "✅ Created new user account for #{customer.display_name}"
    else
      puts "❌ Failed to create user account: #{user.errors.full_messages.join(', ')}"
      return false
    end
  else
    puts "👤 Found existing user account for: #{customer.display_name}"
  end

  # Update password
  user.password = new_password
  user.password_confirmation = new_password

  if user.save(validate: false)
    puts "✅ Password updated successfully for #{customer.display_name} (#{email})"
    puts "📧 Email: #{email}"
    puts "🔑 New Password: #{new_password}"
    return true
  else
    puts "❌ Failed to update password: #{user.errors.full_messages.join(', ')}"
    return false
  end
rescue => e
  puts "❌ Error: #{e.message}"
  return false
end

def change_customer_password_by_mobile(mobile, new_password)
  puts "🔍 Looking for customer with mobile: #{mobile}"

  # Clean mobile number
  clean_mobile = mobile.gsub(/[^0-9]/, '')
  clean_mobile = clean_mobile.last(10) if clean_mobile.length > 10

  # Find customer by mobile
  customer = Customer.where("REPLACE(REPLACE(REPLACE(mobile, '+91', ''), ' ', ''), '-', '') LIKE ?", "%#{clean_mobile}").first
  unless customer
    puts "❌ Customer not found with mobile: #{mobile}"
    return false
  end

  puts "👤 Found customer: #{customer.display_name}"

  if customer.email.present?
    return change_customer_password_by_email(customer.email, new_password)
  else
    puts "❌ Customer does not have an email address. Cannot create/update user account."
    return false
  end
rescue => e
  puts "❌ Error: #{e.message}"
  return false
end

def change_customer_password_by_id(customer_id, new_password)
  puts "🔍 Looking for customer with ID: #{customer_id}"

  customer = Customer.find_by(id: customer_id)
  unless customer
    puts "❌ Customer not found with ID: #{customer_id}"
    return false
  end

  puts "👤 Found customer: #{customer.display_name}"

  if customer.email.present?
    return change_customer_password_by_email(customer.email, new_password)
  else
    puts "❌ Customer does not have an email address. Cannot create/update user account."
    return false
  end
rescue => e
  puts "❌ Error: #{e.message}"
  return false
end

def reset_all_customer_passwords(default_password)
  puts "🔄 Resetting all customer passwords to: #{default_password}"
  puts "⚠️  WARNING: This will change passwords for ALL customers!"
  print "Type 'YES' to continue: "

  # Skip confirmation in script mode
  confirmation = ENV['SKIP_CONFIRMATION'] == 'true' ? 'YES' : STDIN.gets.chomp

  unless confirmation == 'YES'
    puts "❌ Operation cancelled."
    return false
  end

  puts "🚀 Starting password reset for all customers..."

  success_count = 0
  error_count = 0

  Customer.find_each do |customer|
    next if customer.email.blank?

    if change_customer_password_by_email(customer.email, default_password)
      success_count += 1
    else
      error_count += 1
    end
  end

  puts "\n📊 Summary:"
  puts "✅ Successfully updated: #{success_count} customers"
  puts "❌ Errors: #{error_count} customers"
  puts "🔑 Default password set to: #{default_password}"

  return true
rescue => e
  puts "❌ Error during bulk reset: #{e.message}"
  return false
end

def bulk_change_by_email_file(file_path, new_password)
  puts "📁 Reading emails from file: #{file_path}"

  unless File.exist?(file_path)
    puts "❌ File not found: #{file_path}"
    return false
  end

  emails = File.readlines(file_path).map(&:strip).reject(&:empty?)
  puts "📧 Found #{emails.count} emails to process"

  success_count = 0
  error_count = 0

  emails.each_with_index do |email, index|
    puts "\n[#{index + 1}/#{emails.count}] Processing: #{email}"

    if change_customer_password_by_email(email, new_password)
      success_count += 1
    else
      error_count += 1
    end
  end

  puts "\n📊 Bulk Update Summary:"
  puts "✅ Successfully updated: #{success_count} customers"
  puts "❌ Errors: #{error_count} customers"

  return true
rescue => e
  puts "❌ Error during bulk update: #{e.message}"
  return false
end

# Main script execution
if __FILE__ == $0
  puts "🔑 Customer Password Change Script"
  puts "=" * 50

  # Check arguments
  if ARGV.length < 2
    puts "❌ Invalid arguments!"
    puts "\nUsage:"
    puts "  ruby change_customer_password.rb email <email> <new_password>"
    puts "  ruby change_customer_password.rb mobile <mobile> <new_password>"
    puts "  ruby change_customer_password.rb id <customer_id> <new_password>"
    puts "  ruby change_customer_password.rb reset_all <default_password>"
    puts "  ruby change_customer_password.rb bulk_email <file_path> <new_password>"
    exit 1
  end

  command = ARGV[0]

  case command
  when 'email'
    if ARGV.length != 3
      puts "❌ Usage: ruby change_customer_password.rb email <email> <new_password>"
      exit 1
    end

    email = ARGV[1]
    password = ARGV[2]

    if change_customer_password_by_email(email, password)
      puts "\n🎉 Password change completed successfully!"
    else
      puts "\n💥 Password change failed!"
      exit 1
    end

  when 'mobile'
    if ARGV.length != 3
      puts "❌ Usage: ruby change_customer_password.rb mobile <mobile> <new_password>"
      exit 1
    end

    mobile = ARGV[1]
    password = ARGV[2]

    if change_customer_password_by_mobile(mobile, password)
      puts "\n🎉 Password change completed successfully!"
    else
      puts "\n💥 Password change failed!"
      exit 1
    end

  when 'id'
    if ARGV.length != 3
      puts "❌ Usage: ruby change_customer_password.rb id <customer_id> <new_password>"
      exit 1
    end

    customer_id = ARGV[1]
    password = ARGV[2]

    if change_customer_password_by_id(customer_id, password)
      puts "\n🎉 Password change completed successfully!"
    else
      puts "\n💥 Password change failed!"
      exit 1
    end

  when 'reset_all'
    if ARGV.length != 2
      puts "❌ Usage: ruby change_customer_password.rb reset_all <default_password>"
      exit 1
    end

    default_password = ARGV[1]

    if reset_all_customer_passwords(default_password)
      puts "\n🎉 Bulk password reset completed!"
    else
      puts "\n💥 Bulk password reset failed!"
      exit 1
    end

  when 'bulk_email'
    if ARGV.length != 3
      puts "❌ Usage: ruby change_customer_password.rb bulk_email <file_path> <new_password>"
      exit 1
    end

    file_path = ARGV[1]
    password = ARGV[2]

    if bulk_change_by_email_file(file_path, password)
      puts "\n🎉 Bulk password update completed!"
    else
      puts "\n💥 Bulk password update failed!"
      exit 1
    end

  else
    puts "❌ Unknown command: #{command}"
    puts "\nValid commands: email, mobile, id, reset_all, bulk_email"
    exit 1
  end

  puts "\n✨ Script completed!"
end