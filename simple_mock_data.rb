#!/usr/bin/env ruby
# Simple Mock Data Script
# Run this in Rails console

puts "🚀 Creating simplified mock data..."

# Create a few customers and policies

# 1. Create some customers
puts "\n1. Creating 5 customers..."
5.times do |i|
  customer = Customer.find_or_create_by(email: "testcustomer#{i+1}@example.com") do |c|
    c.customer_type = 'individual'
    c.first_name = "Customer#{i+1}"
    c.last_name = "Test"
    c.mobile = "9#{(100000000 + i).to_s}"
    c.gender = ['male', 'female'].sample
    c.birth_date = Date.new(1990, 1, 1)
    c.address = "Test Address #{i+1}"
    c.city = 'Mumbai'
    c.state = 'Maharashtra'
    c.pincode = '400001'
    c.pan_no = "TEST#{i}1234Z"
    c.occupation = 'Software Engineer'
    c.annual_income = 500000
    c.marital_status = 'single'
    c.status = true
    c.added_by = 'system_seed'
  end
  puts "✅ Customer #{i+1}: #{customer.display_name}"
end

# 2. Create some health insurance policies
puts "\n2. Creating 3 health insurance policies..."
customers = Customer.limit(3)
customers.each_with_index do |customer, i|
  policy_number = "HI2025TEST#{i+1}"

  # Skip if policy already exists
  if HealthInsurance.exists?(policy_number: policy_number)
    puts "⚠️ Health policy #{policy_number} already exists, skipping"
    next
  end

  policy = HealthInsurance.create!(
    customer: customer,
    policy_holder: customer.display_name,
    insurance_company_name: 'ICICI Prudential Life Insurance Co Ltd',
    policy_type: 'New',
    policy_number: policy_number,
    policy_booking_date: Date.current,
    policy_start_date: Date.current,
    policy_end_date: Date.current + 1.year,
    payment_mode: 'Yearly',
    sum_insured: 500000,
    net_premium: 25000,
    gst_percentage: 18.0,
    total_premium: 29500,
    plan_name: 'Family Health Plus',
    is_agent_added: false,
    is_customer_added: true,
    is_admin_added: false
  )

  puts "✅ Health Policy: #{policy.policy_number} - #{customer.display_name}"
end

# 3. Create some life insurance policies
puts "\n3. Creating 3 life insurance policies..."
customers = Customer.limit(3)
customers.each_with_index do |customer, i|
  policy_number = "LI2025TEST#{i+1}"

  # Skip if policy already exists
  if LifeInsurance.exists?(policy_number: policy_number)
    puts "⚠️ Life policy #{policy_number} already exists, skipping"
    next
  end

  policy = LifeInsurance.create!(
    customer: customer,
    distributor_id: 1,
    investor_id: 1,
    policy_holder: customer.display_name,
    insured_name: customer.display_name,
    insurance_company_name: 'ICICI Prudential Life Insurance Co Ltd',
    policy_type: 'New',
    policy_number: policy_number,
    policy_booking_date: Date.current,
    policy_start_date: Date.current,
    policy_end_date: Date.current + 20.years,
    policy_term: 20,
    premium_payment_term: 15,
    payment_mode: 'Yearly',
    sum_insured: 1000000,
    net_premium: 15000,
    first_year_gst_percentage: 18.0,
    second_year_gst_percentage: 4.5,
    third_year_gst_percentage: 4.5,
    total_premium: 17700,
    plan_name: 'Term Life Plus',
    is_agent_added: false,
    is_customer_added: true,
    is_admin_added: false
  )

  puts "✅ Life Policy: #{policy.policy_number} - #{customer.display_name}"
end

# Summary
puts "\n" + "="*50
puts "🎉 SIMPLIFIED MOCK DATA COMPLETED!"
puts "="*50
puts "\n📊 SUMMARY:"
puts "👥 Total Customers: #{Customer.count}"
puts "🏥 Total Health Insurance Policies: #{HealthInsurance.count}"
puts "💰 Total Life Insurance Policies: #{LifeInsurance.count}"
puts "🏢 Total Sub Agents: #{SubAgent.count}"
puts "\n🔑 LOGIN CREDENTIALS:"
puts "Admin Email: admin@drwise.com"
puts "Password: password123"
puts "\n✅ Mock data ready for API testing!"