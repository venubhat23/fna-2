#!/usr/bin/env ruby
# Rails script to make a user admin

# Load Rails environment
require_relative 'config/environment'

# Email to make admin
email = 'newuss1ser@example.com'

puts "Looking for user with email: #{email}"

# Find the user
user = User.find_by(email: email)

if user
  puts "User found: #{user.email}"
  puts "Current role: #{user.role || 'No role set'}"
  puts "Current user type: #{user.user_type || 'No user type set'}"

  # Update user to admin
  user.update!(
    role: 'admin',
    user_type: 'admin'
  )

  puts "✅ SUCCESS! User #{email} is now an admin!"
  puts "New role: #{user.role}"
  puts "New user type: #{user.user_type}"
else
  puts "❌ ERROR: User with email #{email} not found!"
  puts "\nExisting users:"
  User.limit(5).each do |u|
    puts "- #{u.email} (#{u.role || 'no role'} / #{u.user_type || 'no type'})"
  end
end