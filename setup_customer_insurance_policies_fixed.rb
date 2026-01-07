#!/usr/bin/env ruby
# Setup Insurance Policies for Customer - FIXED VERSION
# Usage: RAILS_ENV=development bundle exec rails runner setup_customer_insurance_policies_fixed.rb

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

# Health Insurance Policy 1
health_policy_1 = HealthInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name,
  plan_name: 'Star Comprehensive Health Plan',
  policy_number: "SHP#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'Star Health Insurance',
  policy_type: 'New',
  insurance_type: 'Family Floater',
  policy_booking_date: Date.current,
  policy_start_date: Date.current,
  policy_end_date: Date.current + 1.year,
  payment_mode: 'yearly',
  sum_insured: 500000.0,
  net_premium: 21186.0,
  gst_percentage: 18.0,
  total_premium: 25000.0,
  main_agent_commission_percentage: 10.0,
  commission_amount: 2500.0
)
puts "✅ Created Health Policy 1: #{health_policy_1.policy_number} - ₹#{health_policy_1.sum_insured}"

# Health Insurance Policy 2
health_policy_2 = HealthInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name,
  plan_name: 'HDFC ERGO Health Suraksha',
  policy_number: "HES#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'HDFC ERGO General Insurance',
  policy_type: 'New',
  insurance_type: 'Individual',
  policy_booking_date: Date.current + 2.months,
  policy_start_date: Date.current + 2.months,
  policy_end_date: Date.current + 14.months,
  payment_mode: 'yearly',
  sum_insured: 1000000.0,
  net_premium: 33898.0,
  gst_percentage: 18.0,
  total_premium: 40000.0,
  main_agent_commission_percentage: 12.0,
  commission_amount: 4800.0
)
puts "✅ Created Health Policy 2: #{health_policy_2.policy_number} - ₹#{health_policy_2.sum_insured}"

# Health Insurance Policy 3
health_policy_3 = HealthInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name,
  plan_name: 'Care Health Insurance',
  policy_number: "CHI#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'Care Health Insurance',
  policy_type: 'New',
  insurance_type: 'Family Floater',
  policy_booking_date: Date.current + 6.months,
  policy_start_date: Date.current + 6.months,
  policy_end_date: Date.current + 18.months,
  payment_mode: 'yearly',
  sum_insured: 300000.0,
  net_premium: 12712.0,
  gst_percentage: 18.0,
  total_premium: 15000.0,
  main_agent_commission_percentage: 8.0,
  commission_amount: 1200.0
)
puts "✅ Created Health Policy 3: #{health_policy_3.policy_number} - ₹#{health_policy_3.sum_insured}"

puts "\n💼 Creating Life Insurance Policies..."

# Life Insurance Policy 1
life_policy_1 = LifeInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name,
  plan_name: 'LIC Jeevan Anand',
  policy_number: "LIC#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'LIC of India',
  policy_type: 'New',
  policy_booking_date: Date.current,
  policy_start_date: Date.current,
  policy_end_date: Date.current + 20.years,
  payment_mode: 'yearly',
  policy_term: 20,
  premium_payment_term: 10,
  sum_insured: 1000000.0,
  net_premium: 12712.0,
  total_premium: 15000.0,
  nominee_name: 'Emergency Contact',
  nominee_relationship: 'Brother',
  main_agent_commission_percentage: 10.0,
  commission_amount: 1500.0,
  active: true
)
puts "✅ Created Life Policy 1: #{life_policy_1.policy_number} - ₹#{life_policy_1.sum_insured}"

# Life Insurance Policy 2
life_policy_2 = LifeInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name,
  plan_name: 'SBI Life Smart Shield',
  policy_number: "SBI#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'SBI Life Insurance',
  policy_type: 'New',
  policy_booking_date: Date.current + 1.month,
  policy_start_date: Date.current + 1.month,
  policy_end_date: Date.current + 25.years,
  payment_mode: 'yearly',
  policy_term: 25,
  premium_payment_term: 15,
  sum_insured: 2500000.0,
  net_premium: 21186.0,
  total_premium: 25000.0,
  nominee_name: 'Emergency Contact 2',
  nominee_relationship: 'Mother',
  main_agent_commission_percentage: 12.0,
  commission_amount: 3000.0,
  active: true
)
puts "✅ Created Life Policy 2: #{life_policy_2.policy_number} - ₹#{life_policy_2.sum_insured}"

puts "\n🚗 Creating Motor Insurance Policies..."

# Create Policy record first for Motor Insurance
motor_policy_record_1 = Policy.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name,
  insurance_company: 'Bajaj Allianz General Insurance',
  policy_number: "MOTOR#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  policy_type: 'Motor',
  policy_start_date: Date.current,
  policy_end_date: Date.current + 1.year,
  sum_insured: 800000.0,
  premium_amount: 30000.0,
  commission_percentage: 15.0,
  commission_amount: 4500.0,
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
  policy_holder: customer.display_name,
  insurance_company: 'IFFCO Tokio General Insurance',
  policy_number: "BIKE#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  policy_type: 'Motor',
  policy_start_date: Date.current + 15.days,
  policy_end_date: Date.current + 1.year + 15.days,
  sum_insured: 150000.0,
  premium_amount: 5000.0,
  commission_percentage: 10.0,
  commission_amount: 500.0,
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
  policy_holder: customer.display_name,
  insurance_company: 'HDFC ERGO General Insurance',
  policy_number: "TRAVEL#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  policy_type: 'Other',
  policy_start_date: Date.current + 30.days,
  policy_end_date: Date.current + 30.days + 15.days,
  sum_insured: 200000.0,
  premium_amount: 10000.0,
  commission_percentage: 20.0,
  commission_amount: 2000.0,
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
  policy_holder: customer.display_name,
  insurance_company: 'New India Assurance',
  policy_number: "HOME#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  policy_type: 'Other',
  policy_start_date: Date.current + 7.days,
  policy_end_date: Date.current + 1.year + 7.days,
  sum_insured: 5000000.0,
  premium_amount: 20000.0,
  commission_percentage: 8.0,
  commission_amount: 1600.0,
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
  policy_holder: customer.display_name,
  insurance_company: 'Oriental Insurance Company',
  policy_number: "PA#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  policy_type: 'Other',
  policy_start_date: Date.current + 3.days,
  policy_end_date: Date.current + 1.year + 3.days,
  sum_insured: 1000000.0,
  premium_amount: 3000.0,
  commission_percentage: 15.0,
  commission_amount: 450.0,
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
  puts "   #{policy.policy_number} - #{vehicle_info} - ₹#{policy.sum_insured} (Premium: ₹#{policy.premium_amount})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.premium_amount
end

puts "\n🌐 Other Insurance Policies (#{Policy.where(customer: customer, policy_type: 'Other').count}):"
Policy.where(customer: customer, policy_type: 'Other').each do |policy|
  other_detail = policy.other_insurance
  coverage_type = other_detail ? other_detail.other_policy_type : "Other"
  puts "   #{policy.policy_number} - #{coverage_type} - ₹#{policy.sum_insured} (Premium: ₹#{policy.premium_amount})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.premium_amount
end

puts "\n💰 Total Coverage: ₹#{total_sum_insured}"
puts "💳 Total Annual Premium: ₹#{total_premium}"

puts "\n🎉 Successfully created comprehensive insurance portfolio for customer: #{customer.display_name}"
puts "📧 Customer Email: #{customer.email}"
puts "📱 Customer Mobile: #{customer.mobile}"

puts "\n🔧 API Testing Ready!"
puts "You can now test all mobile APIs with this customer's data."
puts "Use customer credentials: newcustomer@example.com / password123"

puts "\n✅ Script completed successfully!"