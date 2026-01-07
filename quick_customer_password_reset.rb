# Quick Customer Password Reset Script
# Simple script for common password reset operations

puts "🔑 Quick Customer Password Reset"
puts "=" * 40

# Default password
DEFAULT_PASSWORD = "Ganesha@123"

def reset_customer_password(identifier, new_password = DEFAULT_PASSWORD)
  puts "\n🔍 Searching for customer: #{identifier}"

  customer = nil

  # Try to find customer by email first
  if identifier.include?('@')
    customer = Customer.find_by(email: identifier)
    search_type = "email"
  # Try by customer ID if it's numeric
  elsif identifier.match?(/^\d+$/)
    customer = Customer.find_by(id: identifier.to_i)
    search_type = "ID"
  else
    # Try by mobile number
    clean_mobile = identifier.gsub(/[^0-9]/, '').last(10)
    customer = Customer.where("REPLACE(REPLACE(REPLACE(mobile, '+91', ''), ' ', ''), '-', '') LIKE ?", "%#{clean_mobile}").first
    search_type = "mobile"
  end

  unless customer
    puts "❌ Customer not found by #{search_type}: #{identifier}"
    return false
  end

  puts "👤 Found: #{customer.display_name}"
  puts "📧 Email: #{customer.email || 'No email'}"
  puts "📱 Mobile: #{customer.mobile || 'No mobile'}"

  if customer.email.blank?
    puts "❌ Customer has no email address. Cannot create/update user account."
    return false
  end

  # Find or create user account
  user = User.find_by(email: customer.email)

  if user
    puts "👤 Found existing user account"
  else
    puts "👤 Creating new user account..."

    # Get customer role
    customer_role = Role.find_by(name: 'customer') || Role.find_by(name: 'Customer')

    user = User.create!(
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
    puts "✅ Created new user account"
  end

  # Update password
  user.password = new_password
  user.password_confirmation = new_password
  user.save!(validate: false)

  puts "✅ Password updated successfully!"
  puts "🔑 New password: #{new_password}"

  return true
rescue => e
  puts "❌ Error: #{e.message}"
  return false
end

# Example usage:
puts "\n📝 Usage Examples:"
puts "To run this script, use one of these commands:"
puts
puts "# Reset by email:"
puts "RAILS_ENV=development bundle exec rails runner quick_customer_password_reset.rb"
puts
puts "# Or manually call the function:"
puts '# reset_customer_password("customer@example.com", "NewPassword123")'
puts '# reset_customer_password("9876543210")'
puts '# reset_customer_password("5")'
puts

# If arguments provided, use them
if ARGV.length >= 1
  identifier = ARGV[0]
  password = ARGV[1] || DEFAULT_PASSWORD

  puts "\n🚀 Running with provided arguments..."
  if reset_customer_password(identifier, password)
    puts "\n🎉 Success!"
  else
    puts "\n💥 Failed!"
  end
else
  puts "💡 Run with arguments: ruby quick_customer_password_reset.rb <email|mobile|id> [password]"
end