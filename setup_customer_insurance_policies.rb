#!/usr/bin/env ruby
# Setup Insurance Policies for Customer
# Usage: RAILS_ENV=development bundle exec rails runner setup_customer_insurance_policies.rb

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
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'Star Comprehensive Health Plan',
  policy_number: "SHP#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'Star Health Insurance',
  policy_type: 'new_policy',
  policy_start_date: Date.current,
  policy_end_date: Date.current + 1.year,
  payment_mode: 'yearly',
  sum_insured: 500000.0,
  net_premium: 21186.0,
  gst_percentage: 18.0,
  total_premium: 25000.0,
  agent_commission_percentage: 10.0,
  commission_amount: 2500.0,
  family_floater: true,
  family_members: ['Spouse'],
  policy_status: 'active'
)
puts "✅ Created Health Policy 1: #{health_policy_1.policy_number} - ₹#{health_policy_1.sum_insured}"

# Health Insurance Policy 2
health_policy_2 = HealthInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'HDFC ERGO Health Suraksha',
  policy_number: "HES#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'HDFC ERGO General Insurance',
  policy_type: 'new_policy',
  policy_start_date: Date.current + 2.months,
  policy_end_date: Date.current + 14.months,
  payment_mode: 'yearly',
  sum_insured: 1000000.0,
  net_premium: 33898.0,
  gst_percentage: 18.0,
  total_premium: 40000.0,
  agent_commission_percentage: 12.0,
  commission_amount: 4800.0,
  family_floater: false,
  policy_status: 'active'
)
puts "✅ Created Health Policy 2: #{health_policy_2.policy_number} - ₹#{health_policy_2.sum_insured}"

# Health Insurance Policy 3
health_policy_3 = HealthInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'Care Health Insurance',
  policy_number: "CHI#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'Care Health Insurance',
  policy_type: 'new_policy',
  policy_start_date: Date.current + 6.months,
  policy_end_date: Date.current + 18.months,
  payment_mode: 'yearly',
  sum_insured: 300000.0,
  net_premium: 12712.0,
  gst_percentage: 18.0,
  total_premium: 15000.0,
  agent_commission_percentage: 8.0,
  commission_amount: 1200.0,
  family_floater: true,
  family_members: ['Son', 'Daughter'],
  policy_status: 'active'
)
puts "✅ Created Health Policy 3: #{health_policy_3.policy_number} - ₹#{health_policy_3.sum_insured}"

puts "\n💼 Creating Life Insurance Policies..."

# Life Insurance Policy 1
life_policy_1 = LifeInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'LIC Jeevan Anand',
  policy_number: "LIC#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'LIC of India',
  policy_type: 'new_policy',
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
  agent_commission_percentage: 10.0,
  commission_amount: 1500.0,
  policy_status: 'active'
)
puts "✅ Created Life Policy 1: #{life_policy_1.policy_number} - ₹#{life_policy_1.sum_insured}"

# Life Insurance Policy 2
life_policy_2 = LifeInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'SBI Life Smart Shield',
  policy_number: "SBI#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'SBI Life Insurance',
  policy_type: 'new_policy',
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
  agent_commission_percentage: 12.0,
  commission_amount: 3000.0,
  policy_status: 'active'
)
puts "✅ Created Life Policy 2: #{life_policy_2.policy_number} - ₹#{life_policy_2.sum_insured}"

puts "\n🚗 Creating Motor Insurance Policies..."

# Motor Insurance Policy 1
motor_policy_1 = MotorInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'Comprehensive Car Insurance',
  policy_number: "MOTOR#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'Bajaj Allianz General Insurance',
  policy_type: 'new_policy',
  policy_start_date: Date.current,
  policy_end_date: Date.current + 1.year,
  payment_mode: 'yearly',
  sum_insured: 800000.0,
  net_premium: 25424.0,
  gst_percentage: 18.0,
  total_premium: 30000.0,
  agent_commission_percentage: 15.0,
  commission_amount: 4500.0,
  vehicle_make: 'Maruti Suzuki',
  vehicle_model: 'Swift VXI',
  vehicle_number: 'KA01AB1234',
  vehicle_year: 2022,
  engine_number: 'ENG123456789',
  chassis_number: 'CHA987654321',
  vehicle_type: 'Four Wheeler',
  policy_status: 'active'
)
puts "✅ Created Motor Policy 1: #{motor_policy_1.policy_number} - #{motor_policy_1.vehicle_make} #{motor_policy_1.vehicle_model}"

# Motor Insurance Policy 2
motor_policy_2 = MotorInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'Two Wheeler Insurance',
  policy_number: "BIKE#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'IFFCO Tokio General Insurance',
  policy_type: 'new_policy',
  policy_start_date: Date.current + 15.days,
  policy_end_date: Date.current + 1.year + 15.days,
  payment_mode: 'yearly',
  sum_insured: 150000.0,
  net_premium: 4237.0,
  gst_percentage: 18.0,
  total_premium: 5000.0,
  agent_commission_percentage: 10.0,
  commission_amount: 500.0,
  vehicle_make: 'Hero',
  vehicle_model: 'Splendor Plus',
  vehicle_number: 'KA01CD5678',
  vehicle_year: 2023,
  engine_number: 'ENG987654321',
  chassis_number: 'CHA123456789',
  vehicle_type: 'Two Wheeler',
  policy_status: 'active'
)
puts "✅ Created Motor Policy 2: #{motor_policy_2.policy_number} - #{motor_policy_2.vehicle_make} #{motor_policy_2.vehicle_model}"

puts "\n🌐 Creating Other Insurance Policies..."

# Other Insurance Policy 1 - Travel
other_policy_1 = OtherInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'International Travel Insurance',
  policy_number: "TRAVEL#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'HDFC ERGO General Insurance',
  policy_type: 'new_policy',
  policy_start_date: Date.current + 30.days,
  policy_end_date: Date.current + 30.days + 15.days,
  payment_mode: 'one_time',
  sum_insured: 200000.0,
  net_premium: 8475.0,
  gst_percentage: 18.0,
  total_premium: 10000.0,
  agent_commission_percentage: 20.0,
  commission_amount: 2000.0,
  coverage_type: 'Travel',
  description: 'Comprehensive travel insurance for international trips with medical and baggage coverage',
  policy_status: 'active'
)
puts "✅ Created Travel Policy: #{other_policy_1.policy_number} - Travel Insurance"

# Other Insurance Policy 2 - Home
other_policy_2 = OtherInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'Home Insurance Comprehensive',
  policy_number: "HOME#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'New India Assurance',
  policy_type: 'new_policy',
  policy_start_date: Date.current + 7.days,
  policy_end_date: Date.current + 1.year + 7.days,
  payment_mode: 'yearly',
  sum_insured: 5000000.0,
  net_premium: 16949.0,
  gst_percentage: 18.0,
  total_premium: 20000.0,
  agent_commission_percentage: 8.0,
  commission_amount: 1600.0,
  coverage_type: 'Property',
  description: 'Comprehensive home insurance covering structure, contents, and liability',
  policy_status: 'active'
)
puts "✅ Created Home Policy: #{other_policy_2.policy_number} - Home Insurance"

# Other Insurance Policy 3 - Personal Accident
other_policy_3 = OtherInsurance.create!(
  customer_id: customer.id,
  user_id: agent.id,
  policy_holder: customer.display_name,
  plan_name: 'Personal Accident Insurance',
  policy_number: "PA#{Date.current.strftime('%Y')}#{customer.id.to_s.rjust(3, '0')}01",
  insurance_company_name: 'Oriental Insurance Company',
  policy_type: 'new_policy',
  policy_start_date: Date.current + 3.days,
  policy_end_date: Date.current + 1.year + 3.days,
  payment_mode: 'yearly',
  sum_insured: 1000000.0,
  net_premium: 2542.0,
  gst_percentage: 18.0,
  total_premium: 3000.0,
  agent_commission_percentage: 15.0,
  commission_amount: 450.0,
  coverage_type: 'Accident',
  description: 'Personal accident insurance providing coverage for accidental death and disability',
  policy_status: 'active'
)
puts "✅ Created Personal Accident Policy: #{other_policy_3.policy_number} - PA Insurance"

puts "\n💰 Creating Premium Installments..."

# Create installments for policies with installment payment modes
policies_with_installments = [health_policy_1, health_policy_2, life_policy_1, life_policy_2, motor_policy_1]

policies_with_installments.each do |policy|
  # Create next 3 installments
  (1..3).each do |i|
    installment_amount = case policy.class.name
    when 'HealthInsurance'
      policy.total_premium / 4  # Quarterly installments
    when 'LifeInsurance'
      policy.total_premium # Annual installments
    when 'MotorInsurance'
      policy.total_premium / 2 # Half-yearly installments
    else
      policy.total_premium
    end

    due_date = case policy.class.name
    when 'HealthInsurance'
      policy.policy_start_date + (i * 3).months
    when 'LifeInsurance'
      policy.policy_start_date + i.years
    when 'MotorInsurance'
      policy.policy_start_date + (i * 6).months
    else
      policy.policy_start_date + i.months
    end

    installment = PremiumInstallment.create!(
      customer_id: customer.id,
      policy_type: policy.class.name,
      policy_id: policy.id,
      installment_number: i,
      due_date: due_date,
      amount: installment_amount,
      status: i == 1 ? 'paid' : 'pending',
      paid_date: i == 1 ? due_date - 5.days : nil,
      payment_method: i == 1 ? 'online' : nil
    )

    puts "   📄 Installment #{i} for #{policy.class.name} #{policy.policy_number}: ₹#{installment_amount} due on #{due_date.strftime('%d-%m-%Y')}"
  end
end

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

puts "\n🚗 Motor Insurance Policies (#{MotorInsurance.where(customer: customer).count}):"
MotorInsurance.where(customer: customer).each do |policy|
  puts "   #{policy.policy_number} - #{policy.vehicle_make} #{policy.vehicle_model} - ₹#{policy.sum_insured} (Premium: ₹#{policy.total_premium})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.total_premium
end

puts "\n🌐 Other Insurance Policies (#{OtherInsurance.where(customer: customer).count}):"
OtherInsurance.where(customer: customer).each do |policy|
  puts "   #{policy.policy_number} - #{policy.coverage_type} - ₹#{policy.sum_insured} (Premium: ₹#{policy.total_premium})"
  total_sum_insured += policy.sum_insured
  total_premium += policy.total_premium
end

puts "\n💰 Total Coverage: ₹#{total_sum_insured}"
puts "💳 Total Annual Premium: ₹#{total_premium}"
puts "📅 Total Installments Created: #{PremiumInstallment.where(customer: customer).count}"

puts "\n🎉 Successfully created comprehensive insurance portfolio for customer: #{customer.display_name}"
puts "📧 Customer Email: #{customer.email}"
puts "📱 Customer Mobile: #{customer.mobile}"

puts "\n🔧 API Testing Ready!"
puts "You can now test all mobile APIs with this customer's data."
puts "Use customer credentials: newcustomer@example.com / password123"

puts "\n✅ Script completed successfully!"