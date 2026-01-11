#!/usr/bin/env ruby
# Simple script to create/update test users with known passwords

puts "🔑 Creating/Updating Test Users..."

# Get role references
admin_role = Role.find_by(name: 'admin') || Role.find_by(id: 2)
agent_role = Role.find_by(name: 'agent') || Role.find_by(id: 3)

# Helper method to create or update user
def create_or_update_user(email, attributes)
  user = User.find_by(email: email)
  if user
    puts "Updating existing user: #{email}"
    user.update!(attributes)
  else
    puts "Creating new user: #{email}"
    user = User.create!(attributes.merge(email: email))
  end
  user
end

# Create/Update Admin User
admin_user = create_or_update_user('admin@dhanvantri.com', {
  first_name: 'Admin',
  last_name: 'User',
  password: 'admin123456',
  password_confirmation: 'admin123456',
  mobile: '9999999999',
  user_type: 'admin',
  role_id: admin_role.id,
  status: true
})

# Create/Update Agent User
agent_user = create_or_update_user('subagent@dhanvantri.com', {
  first_name: 'Rajesh',
  last_name: 'Kumar',
  password: 'subagent123456',
  password_confirmation: 'subagent123456',
  mobile: '9876543210',
  user_type: 'agent',
  role_id: agent_role.id,
  status: true
})

# Create/Update Customer Users
customer1_user = create_or_update_user('customer1@example.com', {
  first_name: 'Priya',
  last_name: 'Sharma',
  password: 'customer123456',
  password_confirmation: 'customer123456',
  mobile: '9876543211',
  user_type: 'customer',
  role_id: agent_role.id,
  status: true
})

customer2_user = create_or_update_user('customer2@example.com', {
  first_name: 'Amit',
  last_name: 'Patel',
  password: 'customer123456',
  password_confirmation: 'customer123456',
  mobile: '9876543212',
  user_type: 'customer',
  role_id: agent_role.id,
  status: true
})

puts "\n✅ Test users ready:"
puts "Admin: admin@dhanvantri.com / admin123456"
puts "Agent: subagent@dhanvantri.com / subagent123456"
puts "Customer1: customer1@example.com / customer123456"
puts "Customer2: customer2@example.com / customer123456"

# Test authentication
puts "\n🔐 Testing authentication..."
[admin_user, agent_user, customer1_user, customer2_user].each do |user|
  test_password = case user.user_type
  when 'admin' then 'admin123456'
  when 'agent' then 'subagent123456'
  when 'customer' then 'customer123456'
  end

  can_auth = user.valid_password?(test_password)
  puts "#{user.email}: #{can_auth ? '✅' : '❌'}"
end