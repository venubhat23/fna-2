# Minimal Test Data for Mobile APIs
puts "🚀 Creating minimal test data..."

begin
  # Just ensure we have users for login testing
  admin = User.find_or_create_by(email: 'admin@example.com') do |user|
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.first_name = 'John'
    user.last_name = 'Doe'
    user.mobile = '9876543210'
    user.user_type = 'agent'
    user.role = 'admin_role'
    user.status = true
  end

  # Create a customer for testing customer APIs
  customer = Customer.find_or_create_by(email: 'rajesh.kumar@example.com') do |c|
    c.customer_type = 'individual'
    c.first_name = 'Rajesh'
    c.last_name = 'Kumar'
    c.mobile = '9876543217'
    c.status = true
    c.added_by = admin.id
  end

  puts "\n✅ BASIC DATA READY!"
  puts "👤 Admin: admin@example.com / password123"
  puts "👤 Customer: rajesh.kumar@example.com / password123"
  puts "\n🚀 Now you can test all Mobile APIs!"

rescue => e
  puts "❌ Error: #{e.message}"
end