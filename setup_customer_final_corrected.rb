#!/usr/bin/env ruby
# Setup Insurance Policies for Customer - FINAL CORRECTED VERSION
# Usage: RAILS_ENV=development bundle exec rails runner setup_customer_final_corrected.rb

puts "🔍 Setting up insurance policies for customer: newcustomer@example.com"

# Find or create the customer
customer = Customer.find_or_create_by(email: 'newcustomer@example.com') do |c|
  c.first_name = 'New'
  c.last_name = 'Customer'
  c.mobile = '9876543220'
  c.gender = 'Male'
  c.birth_date = Date.parse('1990-01-15')
  c.address = '123 Customer Street, Demo City'
  c.city = 'Mumbai'
  c.state = 'Maharashtra'
  c.pincode = '400001'
  c.pan_no = 'NEWCU1234P'
  c.occupation = 'Software Engineer'
  c.annual_income = 1200000
  c.marital_status = 'Single'
  c.customer_type = 'individual'
  puts "✅ Created new customer: #{c.display_name}"
end

puts "📋 Customer Details:"
puts "   Name: #{customer.display_name}"
puts "   Email: #{customer.email}"
puts "   Mobile: #{customer.mobile}"
puts "   ID: #{customer.id}"

# Find an agent to assign policies to
agent = User.where(user_type: 'agent').first
if agent.nil?
  agent = User.create!(
    first_name: 'Demo',
    last_name: 'Agent',
    email: 'demo.agent@insurebook.com',
    mobile: '9999999999',
    user_type: 'agent',
    role: 'agent_role',
    status: true,
    password: 'password123',
    password_confirmation: 'password123'
  )
  puts "✅ Created demo agent: #{agent.first_name} #{agent.last_name}"
else
  puts "✅ Using existing agent: #{agent.first_name} #{agent.last_name}"
end

puts "\n🏥 Creating Health Insurance Policies..."

# Health Insurance Policy 1 (already created successfully)
puts "✅ Health Insurance policies already created successfully"

puts "\n💼 Life Insurance Policies..."
puts "✅ Life Insurance policies already created successfully"

puts "\n🚗 Creating Motor Insurance Policies..."

# Create Policy record first for Motor Insurance with correct attributes
motor_policy_record_1 = Policy.create!(
  customer_id: customer.id,
  user_id: agent.id,
  plan_name: 'Comprehensive Car Insurance',
  policy_number: "MOTOR#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  policy_type: 'Motor',
  policy_start_date: Date.current,
  policy_end_date: Date.current + 1.year,
  sum_insured: 800000.0,
  net_premium: 25424.0,
  gst_percentage: 18.0,
  total_premium: 30000.0,
  status: 'Active'
)

# Motor Insurance Policy 1
motor_policy_1 = MotorInsurance.create!(
  policy_id: motor_policy_record_1.id,
  make: 'Maruti Suzuki',
  model: 'Swift VXI',
  registration_number: 'KA01AB1234',
  mfy: 2022,
  engine_number: 'ENG123456789',
  chassis_number: 'CHA987654321',
  vehicle_type: 'Four Wheeler',
  vehicle_idv: 800000.0,
  total_idv: 800000.0,
  main_agent_commission_percentage: 15.0,
  main_agent_commission_amount: 4500.0
)
puts "✅ Created Motor Policy 1: #{motor_policy_record_1.policy_number} - #{motor_policy_1.make} #{motor_policy_1.model}"

# Create Policy record for second motor insurance
motor_policy_record_2 = Policy.create!(
  customer_id: customer.id,
  user_id: agent.id,
  plan_name: 'Two Wheeler Insurance',
  policy_number: "BIKE#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}02",
  policy_type: 'Motor',
  policy_start_date: Date.current + 15.days,
  policy_end_date: Date.current + 1.year + 15.days,
  sum_insured: 150000.0,
  net_premium: 4237.0,
  gst_percentage: 18.0,
  total_premium: 5000.0,
  status: 'Active'
)

# Motor Insurance Policy 2
motor_policy_2 = MotorInsurance.create!(
  policy_id: motor_policy_record_2.id,
  make: 'Hero',
  model: 'Splendor Plus',
  registration_number: 'KA01CD5678',
  mfy: 2023,
  engine_number: 'ENG987654321',
  chassis_number: 'CHA123456789',
  vehicle_type: 'Two Wheeler',
  vehicle_idv: 150000.0,
  total_idv: 150000.0,
  main_agent_commission_percentage: 10.0,
  main_agent_commission_amount: 500.0
)
puts "✅ Created Motor Policy 2: #{motor_policy_record_2.policy_number} - #{motor_policy_2.make} #{motor_policy_2.model}"

puts "\n🌐 Creating Other Insurance Policies..."

# Create Policy records for Other Insurance
travel_policy_record = Policy.create!(
  customer_id: customer.id,
  user_id: agent.id,
  plan_name: 'International Travel Insurance',
  policy_number: "TRAVEL#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  policy_type: 'Travel',
  policy_start_date: Date.current + 30.days,
  policy_end_date: Date.current + 30.days + 15.days,
  sum_insured: 200000.0,
  net_premium: 8475.0,
  gst_percentage: 18.0,
  total_premium: 10000.0,
  status: 'Active'
)

# Other Insurance Policy 1 - Travel
other_policy_1 = OtherInsurance.create!(
  policy_id: travel_policy_record.id,
  other_policy_type: 'Travel',
  main_agent_commission_percentage: 20.0,
  main_agent_commission_amount: 2000.0
)
puts "✅ Created Travel Policy: #{travel_policy_record.policy_number} - Travel Insurance"

# Home Insurance Policy
home_policy_record = Policy.create!(
  customer_id: customer.id,
  user_id: agent.id,
  plan_name: 'Home Insurance Comprehensive',
  policy_number: "HOME#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}02",
  policy_type: 'Property',
  policy_start_date: Date.current + 7.days,
  policy_end_date: Date.current + 1.year + 7.days,
  sum_insured: 5000000.0,
  net_premium: 16949.0,
  gst_percentage: 18.0,
  total_premium: 20000.0,
  status: 'Active'
)

# Other Insurance Policy 2 - Home
other_policy_2 = OtherInsurance.create!(
  policy_id: home_policy_record.id,
  other_policy_type: 'Property',
  main_agent_commission_percentage: 8.0,
  main_agent_commission_amount: 1600.0
)
puts "✅ Created Home Policy: #{home_policy_record.policy_number} - Home Insurance"

# Personal Accident Policy
pa_policy_record = Policy.create!(
  customer_id: customer.id,
  user_id: agent.id,
  plan_name: 'Personal Accident Insurance',
  policy_number: "PA#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}03",
  policy_type: 'Accident',
  policy_start_date: Date.current + 3.days,
  policy_end_date: Date.current + 1.year + 3.days,
  sum_insured: 1000000.0,
  net_premium: 2542.0,
  gst_percentage: 18.0,
  total_premium: 3000.0,
  status: 'Active'
)

# Other Insurance Policy 3 - Personal Accident
other_policy_3 = OtherInsurance.create!(
  policy_id: pa_policy_record.id,
  other_policy_type: 'Accident',
  main_agent_commission_percentage: 15.0,
  main_agent_commission_amount: 450.0
)
puts "✅ Created Personal Accident Policy: #{pa_policy_record.policy_number} - PA Insurance"

puts "\n🎯 Creating Customer User Account for API Login..."

# Create User account for the customer so they can login via API
customer_user = User.find_or_create_by(email: 'newcustomer@example.com') do |u|
  u.first_name = customer.first_name
  u.last_name = customer.last_name
  u.mobile = customer.mobile
  u.user_type = 'customer'
  u.role = 'customer_role'
  u.status = true
  u.password = 'password123'
  u.password_confirmation = 'password123'
end
puts "✅ Created customer user account: #{customer_user.email}"

puts "\n📊 Summary of Created Policies:"
puts "=" * 50

total_sum_insured = 0
total_premium = 0

puts "\n🏥 Health Insurance Policies (#{HealthInsurance.where(customer: customer).count}):"
HealthInsurance.where(customer: customer).each do |policy|
  puts "   #{policy.policy_number} - #{policy.plan_name} - ₹#{policy.sum_insured} (Premium: ₹#{policy.total_premium})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.total_premium
end

puts "\n💼 Life Insurance Policies (#{LifeInsurance.where(customer: customer).count}):"
LifeInsurance.where(customer: customer).each do |policy|
  puts "   #{policy.policy_number} - #{policy.plan_name} - ₹#{policy.sum_insured} (Premium: ₹#{policy.total_premium})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.total_premium
end

puts "\n🚗 Motor Insurance Policies (#{Policy.where(customer: customer, policy_type: 'Motor').count}):"
Policy.where(customer: customer, policy_type: 'Motor').each do |policy|
  motor_detail = policy.motor_insurance
  vehicle_info = motor_detail ? "#{motor_detail.make} #{motor_detail.model}" : "Vehicle Details"
  puts "   #{policy.policy_number} - #{vehicle_info} - ₹#{policy.sum_insured} (Premium: ₹#{policy.total_premium})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.total_premium
end

puts "\n🌐 Other Insurance Policies:"
other_policies_count = Policy.where(customer: customer).where.not(policy_type: 'Motor').where.not(policy_type: nil).count
puts "   Found #{other_policies_count} other policies"
Policy.where(customer: customer).where.not(policy_type: 'Motor').each do |policy|
  next if policy.policy_type.nil?
  other_detail = policy.other_insurance
  coverage_type = other_detail ? other_detail.other_policy_type : policy.policy_type
  puts "   #{policy.policy_number} - #{coverage_type} - ₹#{policy.sum_insured} (Premium: ₹#{policy.total_premium})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.total_premium
end

puts "\n💰 Total Coverage: ₹#{total_sum_insured}"
puts "💳 Total Annual Premium: ₹#{total_premium}"

puts "\n🎉 Successfully created comprehensive insurance portfolio for customer: #{customer.display_name}"
puts "📧 Customer Email: #{customer.email}"
puts "📱 Customer Mobile: #{customer.mobile}"

puts "\n🔐 Login Credentials Created:"
puts "   Email: newcustomer@example.com"
puts "   Password: password123"
puts "   User Type: customer"

puts "\n🔧 API Testing Ready!"
puts "You can now test all mobile APIs with this customer's data."
puts "Use customer credentials: newcustomer@example.com / password123"

puts "\n✅ Script completed successfully!"