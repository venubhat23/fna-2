#!/usr/bin/env ruby
# Script to generate notification data for customer2@example.com
# Run with: RAILS_ENV=development bundle exec rails runner generate_notification_data.rb

puts "=== Generating Notification Data for customer2@example.com ==="

# Find the customer
customer = Customer.find_by(email: 'customer2@example.com')

unless customer
  puts "❌ Customer with email 'customer2@example.com' not found!"
  exit 1
end

puts "✅ Customer found: #{customer.display_name} (ID: #{customer.id})"

# Get customer's policies
health_policies = HealthInsurance.where(customer: customer)
life_policies = LifeInsurance.where(customer: customer)

puts "\n📋 Current policies:"
puts "  - Health policies: #{health_policies.count}"
puts "  - Life policies: #{life_policies.count}"

# Set policy end dates to trigger notifications
notification_dates = [
  Date.current + 1.month,   # 1 month from today
  Date.current + 15.days,   # 15 days from today
  Date.current + 7.days,    # 1 week from today
  Date.current + 1.day      # Tomorrow
]

puts "\n🔄 Updating policy end dates to trigger notifications..."

# Update health insurance policies
health_policies.each_with_index do |policy, index|
  new_end_date = notification_dates[index % notification_dates.length]

  puts "  📅 Health Policy #{policy.policy_number}: setting end date to #{new_end_date}"

  policy.update_columns(
    policy_end_date: new_end_date,
    notification_dates: nil  # Clear existing notifications to regenerate
  )

  # Manually trigger notification date generation
  policy.send(:set_notification_dates)
end

# Update life insurance policies
life_policies.each_with_index do |policy, index|
  new_end_date = notification_dates[(index + 2) % notification_dates.length]

  puts "  📅 Life Policy #{policy.policy_number}: setting end date to #{new_end_date}"

  policy.update_columns(
    policy_end_date: new_end_date,
    notification_dates: nil  # Clear existing notifications to regenerate
  )

  # Manually trigger notification date generation
  policy.send(:set_notification_dates)
end

puts "\n🔍 Checking generated notifications..."

# Check notifications for each policy
total_notifications = 0

health_policies.reload.each do |policy|
  notifications = policy.notifications_due_today
  if notifications.any?
    puts "  📱 Health Policy #{policy.policy_number}: #{notifications.count} notifications"
    notifications.each do |notif|
      puts "    - #{notif['title']}"
    end
    total_notifications += notifications.count
  end
end

life_policies.reload.each do |policy|
  notifications = policy.notifications_due_today
  if notifications.any?
    puts "  📱 Life Policy #{policy.policy_number}: #{notifications.count} notifications"
    notifications.each do |notif|
      puts "    - #{notif['title']}"
    end
    total_notifications += notifications.count
  end
end

puts "\n✅ Generated #{total_notifications} notifications for today"

# Test the API endpoint
puts "\n🧪 Testing notification API..."
puts "To test, use this JWT token:"

require 'jwt'

payload = {
  user_id: customer.id,
  role: 'customer',
  iat: Time.current.to_i,
  exp: 24.hours.from_now.to_i
}

token = JWT.encode(payload, Rails.application.secret_key_base)
puts token

puts "\nCurl command to test:"
puts "curl -s -H \"Authorization: Bearer #{token}\" \\"
puts "     http://localhost:3000/api/v1/mobile/settings/notifications | python3 -m json.tool"

puts "\n🎉 Notification data generation complete!"