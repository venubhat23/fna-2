#!/usr/bin/env ruby
# Add Upcoming Renewals and Installments for Customer
# Usage: RAILS_ENV=development bundle exec rails runner add_renewals_and_installments.rb

puts "🔄 Adding upcoming renewals and installments for customer: newcustomer@example.com"

# Find the customer
customer = Customer.find_by(email: 'newcustomer@example.com')
if customer.nil?
  puts "❌ Customer not found! Run the setup script first."
  exit
end

puts "📋 Customer: #{customer.display_name} (ID: #{customer.id})"

# Check if Renewal and Installment models exist
renewal_model_exists = false
installment_model_exists = false

begin
  Renewal
  renewal_model_exists = true
rescue NameError
  puts "⚠️ Renewal model not found - will create renewal data using policy end dates"
end

begin
  Installment
  installment_model_exists = true
rescue NameError
  puts "⚠️ Installment model not found - will create upcoming premiums in policies"
end

puts "\n🔄 Creating Upcoming Renewals..."

# Method 1: If Renewal model exists
if renewal_model_exists
  # Create renewals for health and life insurance policies
  HealthInsurance.where(customer: customer).each do |policy|
    Renewal.find_or_create_by(
      customer_id: customer.id,
      policy_type: 'HealthInsurance',
      policy_id: policy.id
    ) do |renewal|
      renewal.renewal_date = policy.policy_end_date
      renewal.premium_amount = policy.total_premium
      renewal.status = 'pending'
      renewal.reminder_sent = false
      renewal.notes = "Annual renewal for #{policy.plan_name}"
    end
    puts "✅ Created renewal for Health Policy: #{policy.policy_number}"
  end

  LifeInsurance.where(customer: customer).each do |policy|
    Renewal.find_or_create_by(
      customer_id: customer.id,
      policy_type: 'LifeInsurance',
      policy_id: policy.id
    ) do |renewal|
      renewal.renewal_date = policy.policy_end_date
      renewal.premium_amount = policy.total_premium
      renewal.status = 'pending'
      renewal.reminder_sent = false
      renewal.notes = "Annual renewal for #{policy.plan_name}"
    end
    puts "✅ Created renewal for Life Policy: #{policy.policy_number}"
  end
else
  # Method 2: Update existing policies with upcoming renewal dates
  puts "📅 Updating policies with upcoming renewal dates..."

  # Update some health policies to expire soon (for testing upcoming renewals API)
  health_policies = HealthInsurance.where(customer: customer).limit(2)
  health_policies.each_with_index do |policy, index|
    new_end_date = Date.current + (index + 1).months
    policy.update!(policy_end_date: new_end_date)
    puts "✅ Updated Health Policy #{policy.policy_number} - expires on #{new_end_date.strftime('%d-%m-%Y')}"
  end

  # Update a life policy to expire soon
  life_policy = LifeInsurance.where(customer: customer).first
  if life_policy
    new_end_date = Date.current + 45.days
    life_policy.update!(policy_end_date: new_end_date)
    puts "✅ Updated Life Policy #{life_policy.policy_number} - expires on #{new_end_date.strftime('%d-%m-%Y')}"
  end
end

puts "\n💳 Creating Upcoming Installments..."

# Method 1: If Installment model exists
if installment_model_exists
  # Create installments for policies with monthly/quarterly payments
  HealthInsurance.where(customer: customer).each_with_index do |policy, index|
    # Create 3 upcoming installments for each policy
    (1..3).each do |installment_number|
      due_date = Date.current + (installment_number * 3).months # Quarterly
      installment_amount = policy.total_premium / 4

      Installment.find_or_create_by(
        customer_id: customer.id,
        policy_type: 'HealthInsurance',
        policy_id: policy.id,
        installment_number: installment_number
      ) do |installment|
        installment.due_date = due_date
        installment.amount = installment_amount
        installment.status = 'pending'
        installment.payment_method = 'auto_debit'
        installment.notes = "Quarterly premium for #{policy.plan_name}"
      end

      puts "   📄 Installment #{installment_number} for #{policy.policy_number}: ₹#{installment_amount} due on #{due_date.strftime('%d-%m-%Y')}"
    end
  end

  LifeInsurance.where(customer: customer).each do |policy|
    # Create annual installments for life insurance
    (1..2).each do |installment_number|
      due_date = Date.current + (installment_number * 12).months # Annual
      installment_amount = policy.total_premium

      Installment.find_or_create_by(
        customer_id: customer.id,
        policy_type: 'LifeInsurance',
        policy_id: policy.id,
        installment_number: installment_number
      ) do |installment|
        installment.due_date = due_date
        installment.amount = installment_amount
        installment.status = 'pending'
        installment.payment_method = 'online'
        installment.notes = "Annual premium for #{policy.plan_name}"
      end

      puts "   📄 Installment #{installment_number} for #{policy.policy_number}: ₹#{installment_amount} due on #{due_date.strftime('%d-%m-%Y')}"
    end
  end
else
  # Method 2: Create a simple installments table or use a generic approach
  puts "📅 Creating upcoming premium schedule..."

  # Update health insurance policies with installment schedule
  HealthInsurance.where(customer: customer).each do |policy|
    # Update payment mode to indicate installments
    policy.update!(payment_mode: 'Quarterly')
    puts "✅ Set #{policy.policy_number} to quarterly payment mode"
  end

  # Update life insurance policies
  LifeInsurance.where(customer: customer).each do |policy|
    policy.update!(payment_mode: 'Yearly')
    puts "✅ Set #{policy.policy_number} to yearly payment mode"
  end
end

puts "\n📊 Summary for API Testing:"
puts "=" * 40

# Count renewals due soon
upcoming_renewals_count = 0
if renewal_model_exists
  upcoming_renewals_count = Renewal.where(customer: customer, status: 'pending').count
else
  # Count policies expiring in next 60 days
  upcoming_renewals_count = HealthInsurance.where(customer: customer)
                                          .where(policy_end_date: Date.current..60.days.from_now).count +
                           LifeInsurance.where(customer: customer)
                                       .where(policy_end_date: Date.current..60.days.from_now).count
end

# Count upcoming installments
upcoming_installments_count = 0
if installment_model_exists
  upcoming_installments_count = Installment.where(customer: customer, status: 'pending').count
else
  # Count based on policies with installment payment modes
  upcoming_installments_count = HealthInsurance.where(customer: customer, payment_mode: 'Quarterly').count * 3 +
                               LifeInsurance.where(customer: customer, payment_mode: 'Yearly').count * 2
end

puts "📅 Upcoming Renewals: #{upcoming_renewals_count}"
puts "💳 Upcoming Installments: #{upcoming_installments_count}"

puts "\n🔧 API Testing URLs:"
puts "GET {{base_url}}/api/v1/mobile/customer/upcoming_renewals"
puts "GET {{base_url}}/api/v1/mobile/customer/upcoming_installments"

puts "\n🔐 Use these credentials:"
puts "Email: newcustomer@example.com"
puts "Password: password123"

puts "\n✅ Renewals and installments setup completed!"
puts "🎯 You can now test the upcoming_renewals and upcoming_installments APIs!"