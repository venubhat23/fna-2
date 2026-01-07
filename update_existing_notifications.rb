#!/usr/bin/env ruby

# Script to update existing insurance records with notifications due today

puts "Updating existing insurance records with notifications due today..."

today = Date.current

# Find existing health insurances
health_insurances = HealthInsurance.all
puts "Found #{health_insurances.count} health insurance records"

health_insurances.each do |insurance|
  next unless insurance.policy_end_date.present?

  # Set notification for today
  notifications = [
    {
      type: 'renewal',
      title: 'Policy Renewal Reminder',
      message: "Your health policy (#{insurance.policy_number}) is due for renewal on #{insurance.policy_end_date.strftime('%d %b %Y')}. Please renew to continue your coverage.",
      date: today.to_s
    }
  ]

  insurance.update_column(:notification_dates, notifications.to_json)
  puts "✅ Updated health insurance #{insurance.policy_number}"
end

# Find existing life insurances
life_insurances = LifeInsurance.all
puts "Found #{life_insurances.count} life insurance records"

life_insurances.each do |insurance|
  next unless insurance.policy_end_date.present?

  # Set notification for today
  notifications = [
    {
      type: 'renewal',
      title: 'Life Policy Renewal Alert',
      message: "Your life policy (#{insurance.policy_number}) expires on #{insurance.policy_end_date.strftime('%d %b %Y')}. Please renew to avoid coverage gap.",
      date: today.to_s
    }
  ]

  insurance.update_column(:notification_dates, notifications.to_json)
  puts "✅ Updated life insurance #{insurance.policy_number}"
end

puts "\n🎉 Existing records updated successfully!"
puts "\nTo test the API:"
puts "1. Make sure you have a customer authentication token"
puts "2. Call GET http://localhost:3000/api/v1/mobile/settings/notifications"
puts "\nExpected response will show notifications due today for all policies."