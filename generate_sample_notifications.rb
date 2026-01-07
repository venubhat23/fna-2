#!/usr/bin/env ruby

# Script to generate sample insurance data with notifications due today

puts "Creating sample insurance data with notifications due today..."

# Create a sample customer if not exists
customer = Customer.find_or_create_by(email: 'test@example.com') do |c|
  c.first_name = 'John'
  c.last_name = 'Doe'
  c.mobile = '9876543210'
  c.customer_type = 'individual'
  c.status = true
end

puts "✅ Customer created/found: #{customer.display_name}"

# Today's date
today = Date.current

# Create Health Insurance with notification due today (expiring in 30 days)
health_expiry_date = today + 30.days
health_insurance = HealthInsurance.find_or_create_by(policy_number: 'HEALTH001') do |hi|
  hi.customer = customer
  hi.policy_holder = 'Self'
  hi.insurance_company_name = 'HDFC ERGO General Insurance Co Ltd'
  hi.policy_type = 'New'
  hi.insurance_type = 'Individual'
  hi.plan_name = 'Health Plus'
  hi.policy_booking_date = today - 330.days
  hi.policy_start_date = today - 335.days
  hi.policy_end_date = health_expiry_date
  hi.payment_mode = 'Yearly'
  hi.sum_insured = 500000
  hi.net_premium = 25000
  hi.gst_percentage = 18
  hi.total_premium = 29500
  hi.policy_term = 1
end

# Save the record first
health_insurance.save!

# Manually set notification_dates to include today
health_notifications = [
  {
    type: 'renewal',
    title: 'Policy Renewal Reminder',
    message: "Your health policy (#{health_insurance.policy_number}) is due for renewal on #{health_expiry_date.strftime('%d %b %Y')}. Please renew to continue your coverage.",
    date: today.to_s
  }
]

health_insurance.update_column(:notification_dates, health_notifications.to_json)
puts "✅ Health Insurance created: #{health_insurance.policy_number} with notification due today"

# Create Life Insurance with notification due today (expiring in 15 days)
life_expiry_date = today + 15.days
life_insurance = LifeInsurance.find_or_create_by(policy_number: 'LIFE001') do |li|
  li.customer = customer
  li.policy_holder = 'Self'
  li.insurance_company_name = 'ICICI Prudential Life Insurance Co Ltd'
  li.policy_type = 'New'
  li.plan_name = 'Jeevan Anand'
  li.insured_name = customer.display_name
  li.policy_booking_date = today - 360.days
  li.policy_start_date = today - 365.days
  li.policy_end_date = life_expiry_date
  li.payment_mode = 'Yearly'
  li.sum_insured = 1000000
  li.net_premium = 50000
  li.first_year_gst_percentage = 18
  li.total_premium = 59000
  li.policy_term = 20
  li.premium_payment_term = 15
end

# Save the record first
life_insurance.save!

# Manually set notification_dates to include today
life_notifications = [
  {
    type: 'renewal',
    title: 'Life Policy Renewal Alert',
    message: "Your life policy (#{life_insurance.policy_number}) expires in 15 days on #{life_expiry_date.strftime('%d %b %Y')}. Please renew to avoid coverage gap.",
    date: today.to_s
  }
]

life_insurance.update_column(:notification_dates, life_notifications.to_json)
puts "✅ Life Insurance created: #{life_insurance.policy_number} with notification due today"

# Add another health insurance with a different type of notification
health_insurance2 = HealthInsurance.find_or_create_by(policy_number: 'HEALTH002') do |hi|
  hi.customer = customer
  hi.policy_holder = 'Self'
  hi.insurance_company_name = 'Star Health Allied Insurance Co Ltd'
  hi.policy_type = 'Renewal'
  hi.insurance_type = 'Family Floater'
  hi.plan_name = 'Star Family Health Optima'
  hi.policy_booking_date = today - 360.days
  hi.policy_start_date = today - 365.days
  hi.policy_end_date = today + 1.day # Expires tomorrow
  hi.payment_mode = 'Yearly'
  hi.sum_insured = 300000
  hi.net_premium = 18000
  hi.gst_percentage = 18
  hi.total_premium = 21240
  hi.policy_term = 1
end

# Save the record first
health_insurance2.save!

# Add a password expiry notification for variety
mixed_notifications = [
  {
    type: 'password',
    title: 'Password Expiry Alert',
    message: 'Your account password will expire in 3 days. Please update your password to maintain account security.',
    date: today.to_s
  }
]

health_insurance2.update_column(:notification_dates, mixed_notifications.to_json)
puts "✅ Additional Health Insurance created: #{health_insurance2.policy_number} with password notification due today"

puts "\n🎉 Sample data created successfully!"
puts "\nTo test the API:"
puts "1. Make sure you have a customer authentication token"
puts "2. Call GET #{ENV['BASE_URL'] || 'http://localhost:3000'}/api/v1/mobile/settings/notifications"
puts "\nExpected response format:"
puts "{"
puts "  \"success\": true,"
puts "  \"data\": ["
puts "    {"
puts "      \"id\": \"health_#{health_insurance.id}_renewal\","
puts "      \"type\": \"renewal\","
puts "      \"title\": \"Policy Renewal Reminder\","
puts "      \"message\": \"Your health policy (#{health_insurance.policy_number}) is due for renewal...\","
puts "      \"date\": \"#{today}\""
puts "    },"
puts "    {"
puts "      \"id\": \"life_#{life_insurance.id}_renewal\","
puts "      \"type\": \"renewal\","
puts "      \"title\": \"Life Policy Renewal Alert\","
puts "      \"message\": \"Your life policy (#{life_insurance.policy_number}) expires in 15 days...\","
puts "      \"date\": \"#{today}\""
puts "    },"
puts "    {"
puts "      \"id\": \"health_#{health_insurance2.id}_password\","
puts "      \"type\": \"password\","
puts "      \"title\": \"Password Expiry Alert\","
puts "      \"message\": \"Your account password will expire in 3 days...\","
puts "      \"date\": \"#{today}\""
puts "    }"
puts "  ]"
puts "}"