#!/usr/bin/env ruby
# Fix Upcoming Installments for Customer API
# Usage: RAILS_ENV=development bundle exec rails runner fix_upcoming_installments.rb

puts "🔧 Fixing upcoming installments for customer: newcustomer@example.com"

# Find the customer
customer = Customer.find_by(email: 'newcustomer@example.com')
if customer.nil?
  puts "❌ Customer not found! Run the setup script first."
  exit
end

puts "📋 Customer: #{customer.display_name} (ID: #{customer.id})"

puts "\n💳 Setting up installment autopay dates for Health Insurance policies..."

# Update Health Insurance policies with installment autopay dates
health_policies = HealthInsurance.where(customer: customer)
health_policies.each_with_index do |policy, index|
  # Set installment autopay start date to a recent date
  autopay_start_date = Date.current - (index + 1).months
  autopay_end_date = policy.policy_end_date

  # Update payment mode to enable installments
  payment_modes = ['Quarterly', 'Monthly', 'Half Yearly']
  selected_payment_mode = payment_modes[index % payment_modes.length]

  policy.update!(
    payment_mode: selected_payment_mode,
    installment_autopay_start_date: autopay_start_date,
    installment_autopay_end_date: autopay_end_date
  )

  puts "✅ Updated Health Policy #{policy.policy_number}:"
  puts "   Payment Mode: #{selected_payment_mode}"
  puts "   Autopay Start: #{autopay_start_date.strftime('%d-%m-%Y')}"
  puts "   Autopay End: #{autopay_end_date.strftime('%d-%m-%Y')}"
end

puts "\n💼 Setting up installment autopay dates for Life Insurance policies..."

# Update Life Insurance policies with installment autopay dates
life_policies = LifeInsurance.where(customer: customer)
life_policies.each_with_index do |policy, index|
  # Set installment autopay start date
  autopay_start_date = Date.current - (index + 2).months
  autopay_end_date = policy.policy_end_date

  # Life insurance typically has yearly or half-yearly payments
  payment_modes = ['Yearly', 'Half Yearly']
  selected_payment_mode = payment_modes[index % payment_modes.length]

  policy.update!(
    payment_mode: selected_payment_mode,
    installment_autopay_start_date: autopay_start_date,
    installment_autopay_end_date: autopay_end_date
  )

  puts "✅ Updated Life Policy #{policy.policy_number}:"
  puts "   Payment Mode: #{selected_payment_mode}"
  puts "   Autopay Start: #{autopay_start_date.strftime('%d-%m-%Y')}"
  puts "   Autopay End: #{autopay_end_date.strftime('%d-%m-%Y')}"
end

puts "\n🧮 Testing installment calculations..."

# Test the calculation logic that the API uses
def calculate_next_installment_date(start_date, payment_mode)
  case payment_mode.downcase
  when 'monthly'
    # Find next monthly installment
    current_date = Date.current
    next_month = start_date
    while next_month <= current_date
      next_month = next_month + 1.month
    end
    next_month
  when 'quarterly'
    # Find next quarterly installment
    current_date = Date.current
    next_quarter = start_date
    while next_quarter <= current_date
      next_quarter = next_quarter + 3.months
    end
    next_quarter
  when 'half yearly', 'half_yearly'
    # Find next half-yearly installment
    current_date = Date.current
    next_half_year = start_date
    while next_half_year <= current_date
      next_half_year = next_half_year + 6.months
    end
    next_half_year
  when 'yearly'
    # Find next yearly installment
    current_date = Date.current
    next_year = start_date
    while next_year <= current_date
      next_year = next_year + 1.year
    end
    next_year
  else
    nil
  end
end

def calculate_installment_amount(total_premium, payment_mode)
  case payment_mode.downcase
  when 'monthly'
    total_premium / 12.0
  when 'quarterly'
    total_premium / 4.0
  when 'half yearly', 'half_yearly'
    total_premium / 2.0
  when 'yearly'
    total_premium
  else
    total_premium
  end
end

# Test calculations for each policy
puts "\n📊 Upcoming Installments Preview:"
puts "=" * 50

health_policies.each do |policy|
  next_installment = calculate_next_installment_date(policy.installment_autopay_start_date, policy.payment_mode)
  installment_amount = calculate_installment_amount(policy.total_premium, policy.payment_mode)

  if next_installment && next_installment <= 30.days.from_now
    days_until = (next_installment - Date.current).to_i
    puts "🏥 #{policy.policy_number} (#{policy.payment_mode})"
    puts "   Next Payment: #{next_installment.strftime('%d-%m-%Y')} (in #{days_until} days)"
    puts "   Amount: ₹#{installment_amount.round(2)}"
    puts ""
  end
end

life_policies.each do |policy|
  next_installment = calculate_next_installment_date(policy.installment_autopay_start_date, policy.payment_mode)
  installment_amount = calculate_installment_amount(policy.total_premium, policy.payment_mode)

  if next_installment && next_installment <= 30.days.from_now
    days_until = (next_installment - Date.current).to_i
    puts "💼 #{policy.policy_number} (#{policy.payment_mode})"
    puts "   Next Payment: #{next_installment.strftime('%d-%m-%Y')} (in #{days_until} days)"
    puts "   Amount: ₹#{installment_amount.round(2)}"
    puts ""
  end
end

puts "\n🔧 API Testing Information:"
puts "=" * 40
puts "🌐 Endpoint: GET {{base_url}}/api/v1/mobile/customer/upcoming_installments"
puts "🔐 Authorization: Bearer {{customer_token}}"
puts "📧 Email: newcustomer@example.com"
puts "🔑 Password: password123"

puts "\n📋 Expected Response Format:"
puts "{"
puts '  "success": true,'
puts '  "data": {'
puts '    "upcoming_installments": ['
puts '      {'
puts '        "id": 1,'
puts '        "insurance_name": "Policy Name",'
puts '        "insurance_type": "Health",'
puts '        "policy_number": "SHP202500201",'
puts '        "next_installment_date": "2025-01-09",'
puts '        "installment_amount": 6250.0'
puts '      }'
puts '    ],'
puts '    "total_installments": 1,'
puts '    "total_amount": 6250.0'
puts '  }'
puts "}"

puts "\n✅ Upcoming installments setup completed!"
puts "🎯 The API should now return installment data for the customer."

# Quick verification
puts "\n🔍 Quick Verification:"
puts "Health Policies with autopay: #{HealthInsurance.where(customer: customer).where.not(installment_autopay_start_date: nil).count}"
puts "Life Policies with autopay: #{LifeInsurance.where(customer: customer).where.not(installment_autopay_start_date: nil).count}"