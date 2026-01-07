#!/usr/bin/env ruby

puts "🚀 Creating comprehensive mock data for InsureBook Admin..."

# 1. Create Brokers
puts "\n🤝 Creating Brokers..."
brokers_data = [
  { name: "Star Health Insurance Broker", status: "active" },
  { name: "HDFC ERGO Insurance Broker", status: "active" },
  { name: "Care Health Insurance Broker", status: "active" }
]

brokers_data.each do |broker_data|
  broker = Broker.find_or_create_by(name: broker_data[:name]) do |b|
    b.status = broker_data[:status]
  end
  puts "  ✓ Created broker: #{broker.name}"
end

# 2. Create Agency Codes
puts "\n🏷️ Creating Agency Codes..."
agency_codes_data = [
  {
    code: "BA000424798",
    insurance_type: "Health",
    company_name: "Star Health Allied Insurance Co Ltd",
    agent_name: "Bharath D"
  },
  {
    code: "HL001234567", 
    insurance_type: "Health",
    company_name: "HDFC ERGO Health Insurance",
    agent_name: "Rajesh Kumar"
  }
]

agency_codes_data.each do |ac_data|
  agency_code = AgencyCode.find_or_create_by(code: ac_data[:code]) do |ac|
    ac.insurance_type = ac_data[:insurance_type]
    ac.company_name = ac_data[:company_name]
    ac.agent_name = ac_data[:agent_name]
  end
  puts "  ✓ Created agency code: #{agency_code.code}"
end

# 3. Create Users
puts "\n👤 Creating Users..."

# Admin
admin = User.find_or_create_by(email: "admin@insurebook.com") do |u|
  u.first_name = "Super"
  u.last_name = "Admin"
  u.mobile = "9876543200"
  u.user_type = "admin"
  u.role = "super_admin"
  u.status = true
  u.password = "password123"
  u.password_confirmation = "password123"
end
puts "  ✓ Created admin: #{admin.email}"

# Agent
agent = User.find_or_create_by(email: "agent1@insurebook.com") do |u|
  u.first_name = "Rajesh"
  u.last_name = "Kumar"
  u.mobile = "9876543201"
  u.user_type = "agent"
  u.role = "agent_role"
  u.status = true
  u.password = "password123"
  u.password_confirmation = "password123"
end
puts "  ✓ Created agent: #{agent.email}"

# 4. Create Sub Agents
puts "\n👥 Creating Sub Agents..."
sub_agent = SubAgent.find_or_create_by(email: "subagent1@insurebook.com") do |sa|
  sa.first_name = "Sneha"
  sa.last_name = "Patel"
  sa.mobile = "9876543210"
  sa.role_id = 1
  sa.status = "active"
  sa.gender = "Female"
end
puts "  ✓ Created sub-agent: #{sub_agent.email}"

# 5. Create Customers
puts "\n👨‍👩‍👧‍👦 Creating Customers..."
customers_data = [
  {
    email: "customer1@test.com",
    first_name: "John",
    last_name: "Doe",
    mobile: "9988776651"
  },
  {
    email: "customer2@test.com", 
    first_name: "Priya",
    last_name: "Sharma",
    mobile: "9988776652"
  },
  {
    email: "customer3@test.com",
    first_name: "Rajesh", 
    last_name: "Kumar",
    mobile: "9988776653"
  }
]

customers_data.each do |customer_data|
  customer = Customer.find_or_create_by(email: customer_data[:email]) do |c|
    c.customer_type = "individual"
    c.first_name = customer_data[:first_name]
    c.last_name = customer_data[:last_name]
    c.mobile = customer_data[:mobile]
    c.status = true
    c.added_by = 'mock_script'
  end
  puts "  ✓ Created customer: #{customer.email}"
end

# 6. Create Health Insurance Policies
puts "\n🏥 Creating Health Insurance Policies..."
customers = Customer.where("email LIKE '%@test.com'")

customers.each_with_index do |customer, index|
  policy_number = "SH#{rand(10000..99999)}"
  
  policy = HealthInsurance.find_or_create_by(policy_number: policy_number) do |hi|
    hi.customer = customer
    hi.sub_agent = sub_agent
    hi.policy_holder = "Self"
    hi.plan_name = "Test Health Plan #{index + 1}"
    hi.insurance_company_name = "Star Health Insurance"
    hi.policy_type = "New"
    hi.insurance_type = "Individual"
    hi.sum_insured = 500000
    hi.net_premium = 15000
    hi.total_premium = 17700
    hi.payment_mode = "Yearly"
    hi.policy_booking_date = 2.months.ago
    hi.policy_start_date = 2.months.ago
    hi.policy_end_date = 10.months.from_now
    hi.gst_percentage = 18
  end
  puts "  ✓ Created health policy: #{policy.policy_number} for #{customer.display_name}"
end

# 7. Create Life Insurance Policies
puts "\n🛡️ Creating Life Insurance Policies..."

customers.limit(2).each_with_index do |customer, index|
  policy_number = "LIC#{rand(100000..999999)}"
  
  policy = LifeInsurance.find_or_create_by(policy_number: policy_number) do |li|
    li.customer = customer
    li.sub_agent = sub_agent
    li.policy_holder = "Self"
    li.plan_name = "Test Life Plan #{index + 1}"
    li.insurance_company_name = "LIC of India"
    li.policy_type = "New"
    li.sum_insured = 1000000
    li.net_premium = 50000
    li.total_premium = 59000
    li.policy_term = 20
    li.premium_payment_term = 15
    li.payment_mode = "Yearly"
    li.policy_booking_date = 6.months.ago
    li.policy_start_date = 6.months.ago
    li.policy_end_date = 19.years.from_now
    li.nominee_name = "Test Nominee"
    li.nominee_relationship = "spouse"
    li.first_year_gst_percentage = 18
  end
  puts "  ✓ Created life policy: #{policy.policy_number} for #{customer.display_name}"
end

# Summary
puts "\n📊 MOCK DATA SUMMARY"
puts "=" * 50
puts "🏢 Brokers: #{Broker.count}"
puts "🏷️ Agency Codes: #{AgencyCode.count}"
puts "👤 Users: #{User.count}"
puts "👥 Sub Agents: #{SubAgent.count}"
puts "👨‍👩‍👧‍👦 Customers: #{Customer.count}"
puts "🏥 Health Policies: #{HealthInsurance.count}"
puts "🛡️ Life Policies: #{LifeInsurance.count}"

total_premium = HealthInsurance.sum(:total_premium) + LifeInsurance.sum(:total_premium)
puts "💰 Total Premium: ₹#{total_premium}"

puts "\n🧪 Test Credentials:"
puts "Admin: admin@insurebook.com / password123"
puts "Agent: agent1@insurebook.com / password123"
puts "Customer (API): customer1@test.com"

puts "\n✅ Mock data generation completed!"
