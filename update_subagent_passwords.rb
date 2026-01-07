# Script to update all sub_agent passwords to password123
puts "Starting password update for all SubAgents..."

updated_count = 0
failed_count = 0

SubAgent.find_each do |sub_agent|
  begin
    # Update password using has_secure_password
    sub_agent.password = 'password123'
    sub_agent.password_confirmation = 'password123'

    # Force update plain_password field
    sub_agent.plain_password = 'password123'

    # Save without validations to ensure it goes through
    if sub_agent.save(validate: false)
      updated_count += 1
      puts "✅ Updated: #{sub_agent.email}"

      # Also update corresponding User account if it exists
      user = User.find_by(email: sub_agent.email)
      if user
        user.password = 'password123'
        user.password_confirmation = 'password123'
        user.save(validate: false)
      end
    else
      failed_count += 1
      puts "❌ Failed: #{sub_agent.email}"
    end
  rescue => e
    failed_count += 1
    puts "❌ Error for #{sub_agent.email}: #{e.message}"
  end
end

puts "\n" + "="*50
puts "📊 Password Update Summary"
puts "="*50
puts "✅ Successfully updated: #{updated_count} sub_agents"
puts "❌ Failed to update: #{failed_count} sub_agents" if failed_count > 0
puts "🔑 New password for all: password123"
puts "="*50