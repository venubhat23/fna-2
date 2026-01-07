# Quick script to update sub_agent passwords
require 'bcrypt'

new_password = 'password123'
encrypted_password = BCrypt::Password.create(new_password)

# Direct SQL update for plain_password
ActiveRecord::Base.connection.execute("
  UPDATE sub_agents
  SET plain_password = '#{new_password}',
      password_digest = '#{encrypted_password}',
      updated_at = NOW()
")

count = SubAgent.count
puts "✅ Successfully updated passwords for #{count} sub_agents"
puts "🔑 New password: #{new_password}"

# Also update User accounts for sub_agents
User.where(user_type: 'sub_agent').update_all(
  password_digest: encrypted_password,
  updated_at: Time.current
)

puts "✅ Also updated corresponding User accounts"