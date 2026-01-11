#!/usr/bin/env ruby
# Mock Data Creation Script for Dhanvantri Admin
# This script creates comprehensive test data including sub-agents, customers, policies, etc.

puts "🚀 Starting Mock Data Creation Script..."
puts "=" * 50

# Get existing role records for different purposes
puts "📝 Getting Role Records..."

# UserRole - for SubAgent, Distributor, Investor
admin_user_role = UserRole.find_by(name: 'Admin') || UserRole.find_by(id: 1)
agent_user_role = UserRole.find_by(name: 'Agent') || UserRole.find_by(id: 2)
customer_user_role = UserRole.find_by(name: 'Customer') || UserRole.find_by(id: 9)

# Role - for User model (permission-based)
admin_role = Role.find_by(name: 'admin') || Role.find_by(id: 2)
agent_role = Role.find_by(name: 'agent') || Role.find_by(id: 3)
# No customer role in Role table, will use admin_role as fallback

puts "✅ Role records found - UserRoles: #{UserRole.count}, Roles: #{Role.count}"

# Create Users (Admin, Agent, Customer)
puts "👥 Creating Users..."

# Create Admin User
admin_user = User.find_or_create_by(email: 'admin@dhanvantri.com') do |user|
  user.first_name = 'Admin'
  user.last_name = 'User'
  user.password = 'admin123456'
  user.mobile = '9999999999'
  user.user_type = 'admin'
  user.role_id = admin_role.id
  user.status = true
end

# Create Sub-Agent User with Password
subagent_user = User.find_or_create_by(email: 'subagent@dhanvantri.com') do |user|
  user.first_name = 'Rajesh'
  user.last_name = 'Kumar'
  user.password = 'subagent123456'
  user.mobile = '9876543210'
  user.user_type = 'agent'
  user.role_id = agent_role.id
  user.status = true
end

# Create Customer Users (using agent role as fallback since no customer role in Role table)
customer1_user = User.find_or_create_by(email: 'customer1@example.com') do |user|
  user.first_name = 'Priya'
  user.last_name = 'Sharma'
  user.password = 'customer123456'
  user.mobile = '9876543211'
  user.user_type = 'customer'
  user.role_id = agent_role.id  # Using agent role as fallback
  user.status = true
end

customer2_user = User.find_or_create_by(email: 'customer2@example.com') do |user|
  user.first_name = 'Amit'
  user.last_name = 'Patel'
  user.password = 'customer123456'
  user.mobile = '9876543212'
  user.user_type = 'customer'
  user.role_id = agent_role.id  # Using agent role as fallback
  user.status = true
end

puts "✅ Users created: #{User.count}"

# Create Sub-Agent
puts "🤵 Creating Sub-Agents..."
subagent = SubAgent.find_or_create_by(email: 'subagent@dhanvantri.com') do |agent|
  agent.first_name = 'Rajesh'
  agent.last_name = 'Kumar'
  agent.mobile = '9876543210'
  agent.role_id = agent_user_role.id
  agent.birth_date = Date.parse('1990-05-15')
  agent.gender = 'Male'
  agent.pan_no = 'ABCDE1234F'
  agent.address = '123 Main Street, Andheri West, Mumbai'
  agent.bank_name = 'HDFC Bank'
  agent.account_no = '12345678901234'
  agent.ifsc_code = 'HDFC0001234'
  agent.account_holder_name = 'Rajesh Kumar'
  agent.account_type = 'Savings'
  agent.status = :active
end

puts "✅ Sub-Agents created: #{SubAgent.count}"

# Create Distributors
puts "🏢 Creating Distributors..."
distributor1 = Distributor.find_or_create_by(email: 'distributor1@dhanvantri.com') do |dist|
  dist.first_name = 'Suresh'
  dist.last_name = 'Agarwal'
  dist.mobile = '9876543213'
  dist.role_id = admin_user_role.id  # Using Admin UserRole
  dist.birth_date = Date.parse('1985-08-20')
  dist.gender = 'Male'
  dist.pan_no = 'FGHIJ5678K'
  dist.address = '456 Business Street, Koramangala, Bangalore'
  dist.bank_name = 'ICICI Bank'
  dist.account_no = '98765432109876'
  dist.ifsc_code = 'ICIC0001234'
  dist.account_holder_name = 'Suresh Agarwal'
  dist.account_type = 'Current'
  dist.status = :active
end

distributor2 = Distributor.find_or_create_by(email: 'distributor2@dhanvantri.com') do |dist|
  dist.first_name = 'Meena'
  dist.last_name = 'Shah'
  dist.mobile = '9876543214'
  dist.role_id = admin_user_role.id  # Using Admin UserRole
  dist.birth_date = Date.parse('1988-12-10')
  dist.gender = 'Female'
  dist.pan_no = 'LMNOP9012Q'
  dist.address = '789 Commerce Road, Baner, Pune'
  dist.bank_name = 'SBI'
  dist.account_no = '11223344556677'
  dist.ifsc_code = 'SBIN0001234'
  dist.account_holder_name = 'Meena Shah'
  dist.account_type = 'Savings'
  dist.status = :active
end

puts "✅ Distributors created: #{Distributor.count}"

# Create Investors
puts "💰 Creating Investors..."
investor1 = Investor.find_or_create_by(email: 'investor1@dhanvantri.com') do |inv|
  inv.first_name = 'Vikram'
  inv.last_name = 'Reddy'
  inv.mobile = '9876543215'
  inv.role_id = admin_user_role.id  # Using Admin UserRole
  inv.birth_date = Date.parse('1980-03-25')
  inv.gender = 'Male'
  inv.pan_no = 'RSTUV3456W'
  inv.address = '321 Investment Avenue, Whitefield, Bangalore'
  inv.bank_name = 'Axis Bank'
  inv.account_no = '55667788990011'
  inv.ifsc_code = 'UTIB0001234'
  inv.account_holder_name = 'Vikram Reddy'
  inv.account_type = 'Savings'
  inv.status = :active
end

investor2 = Investor.find_or_create_by(email: 'investor2@dhanvantri.com') do |inv|
  inv.first_name = 'Kavya'
  inv.last_name = 'Menon'
  inv.mobile = '9876543216'
  inv.role_id = admin_user_role.id  # Using Admin UserRole
  inv.birth_date = Date.parse('1992-07-18')
  inv.gender = 'Female'
  inv.pan_no = 'XYZAB7890C'
  inv.address = '654 Finance Street, Bandra, Mumbai'
  inv.bank_name = 'Kotak Mahindra Bank'
  inv.account_no = '99887766554433'
  inv.ifsc_code = 'KKBK0001234'
  inv.account_holder_name = 'Kavya Menon'
  inv.account_type = 'Savings'
  inv.status = :active
end

puts "✅ Investors created: #{Investor.count}"

# Create Customers
puts "👨‍👩‍👧‍👦 Creating Customers..."
customer1 = Customer.find_or_create_by(email: 'customer1@example.com') do |customer|
  customer.first_name = 'Priya'
  customer.last_name = 'Sharma'
  customer.mobile = '9876543211'
  customer.birth_date = Date.parse('1995-06-12')
  customer.gender = 'Female'
  customer.pan_no = 'DEFGH2345I'
  customer.address = '101 Residential Complex, Powai, Mumbai'
  customer.status = true
end

customer2 = Customer.find_or_create_by(email: 'customer2@example.com') do |customer|
  customer.first_name = 'Amit'
  customer.last_name = 'Patel'
  customer.mobile = '9876543212'
  customer.birth_date = Date.parse('1988-11-30')
  customer.gender = 'Male'
  customer.pan_no = 'JKLMN6789O'
  customer.address = '202 Tech Park, Electronic City, Bangalore'
  customer.status = true
end

customer3 = Customer.find_or_create_by(email: 'customer3@example.com') do |customer|
  customer.first_name = 'Anita'
  customer.last_name = 'Desai'
  customer.mobile = '9876543217'
  customer.birth_date = Date.parse('1991-04-08')
  customer.gender = 'Female'
  customer.pan_no = 'PQRST4567U'
  customer.company_name = 'Desai Enterprises'
  customer.address = '303 Business Hub, Hinjewadi, Pune'
  customer.status = true
end

customer4 = Customer.find_or_create_by(email: 'customer4@example.com') do |customer|
  customer.first_name = 'Ravi'
  customer.last_name = 'Gupta'
  customer.mobile = '9876543218'
  customer.birth_date = Date.parse('1987-03-22')
  customer.gender = 'Male'
  customer.pan_no = 'UVWXY8901Z'
  customer.address = '404 Tech City, Salt Lake, Kolkata'
  customer.status = true
end

puts "✅ Customers created: #{Customer.count}"

# Create Agency Codes
puts "🏛️ Creating Agency Codes..."
agency_code1 = AgencyCode.find_or_create_by(code: 'HDFC001') do |ac|
  ac.company_name = 'HDFC Life'
  ac.insurance_type = 'Life'
  ac.agent_name = 'Rajesh Kumar'
end

agency_code2 = AgencyCode.find_or_create_by(code: 'ICICI002') do |ac|
  ac.company_name = 'ICICI Lombard'
  ac.insurance_type = 'Health'
  ac.agent_name = 'Rajesh Kumar'
end

puts "✅ Agency Codes created: #{AgencyCode.count}"

# Create Brokers
puts "🤝 Creating Brokers..."
broker1 = Broker.find_or_create_by(name: 'Mumbai Insurance Brokers') do |broker|
  broker.status = true
end

broker2 = Broker.find_or_create_by(name: 'Bangalore Financial Services') do |broker|
  broker.status = true
end

puts "✅ Brokers created: #{Broker.count}"

# Create System Settings
puts "⚙️ Creating System Settings..."
SystemSetting.set_company_expenses_percentage(2.0)

puts "✅ System Settings configured"

# Create Life Insurance Policies
puts "📋 Creating Life Insurance Policies..."

life_policy1 = LifeInsurance.find_or_create_by(policy_number: 'LIFE001') do |policy|
  policy.customer = customer1
  policy.sub_agent = subagent
  policy.distributor = distributor1
  policy.investor = investor1
  policy.agency_code = agency_code1
  policy.broker = broker1
  policy.policy_holder = 'Self'
  policy.insured_name = customer1.display_name
  policy.insurance_company_name = 'HDFC Life'
  policy.policy_type = 'New'
  policy.payment_mode = 'Yearly'
  policy.policy_booking_date = Date.current - 30.days
  policy.policy_start_date = Date.current
  policy.policy_end_date = Date.current + 10.years
  policy.risk_start_date = Date.current
  policy.policy_term = 10
  policy.premium_payment_term = 10
  policy.plan_name = 'HDFC Life Term Plan'
  policy.sum_insured = 1000000
  policy.net_premium = 15000
  policy.first_year_gst_percentage = 18
  policy.total_premium = 17700
  policy.company_expenses_percentage = 2.0
  policy.main_agent_commission_percentage = 10
  policy.sub_agent_commission_percentage = 2.0
  policy.distributor_commission_percentage = 1.0
  policy.investor_commission_percentage = 2.0
  policy.nominee_name = 'Rohit Sharma'
  policy.nominee_relationship = 'Spouse'
  policy.nominee_age = 32
  policy.bank_name = 'HDFC Bank'
  policy.account_type = 'Savings'
  policy.account_number = '12345678901234'
  policy.ifsc_code = 'HDFC0001234'
  policy.account_holder_name = customer1.display_name
end

life_policy2 = LifeInsurance.find_or_create_by(policy_number: 'LIFE002') do |policy|
  policy.customer = customer2
  policy.sub_agent = subagent
  policy.distributor = distributor2
  policy.investor = investor2
  policy.policy_holder = 'Self'
  policy.insured_name = customer2.display_name
  policy.insurance_company_name = 'ICICI Prudential'
  policy.policy_type = 'New'
  policy.payment_mode = 'Yearly'
  policy.policy_booking_date = Date.current - 15.days
  policy.policy_start_date = Date.current + 5.days
  policy.policy_end_date = Date.current + 15.years
  policy.policy_term = 15
  policy.premium_payment_term = 10
  policy.plan_name = 'ICICI Prudential Whole Life'
  policy.sum_insured = 2000000
  policy.net_premium = 25000
  policy.first_year_gst_percentage = 18
  policy.total_premium = 29500
  policy.company_expenses_percentage = 2.5
  policy.main_agent_commission_percentage = 12
  policy.sub_agent_commission_percentage = 2.5
  policy.distributor_commission_percentage = 1.5
  policy.investor_commission_percentage = 2.0
  policy.nominee_name = 'Neha Patel'
  policy.nominee_relationship = 'Spouse'
  policy.nominee_age = 28
  policy.bank_name = 'ICICI Bank'
  policy.account_type = 'Savings'
  policy.account_number = '98765432109876'
  policy.ifsc_code = 'ICIC0001234'
  policy.account_holder_name = customer2.display_name
end

puts "✅ Life Insurance Policies created: #{LifeInsurance.count}"

# Create Health Insurance Policies
puts "🏥 Creating Health Insurance Policies..."

health_policy1 = HealthInsurance.find_or_create_by(policy_number: 'HEALTH001') do |policy|
  policy.customer = customer1
  policy.policy_holder = customer1.display_name
  policy.plan_name = 'Family Health Plan'
  policy.insurance_company_name = 'ICICI Lombard'
  policy.insurance_type = 'Family'
  policy.policy_type = 'New'
  policy.policy_booking_date = Date.current - 20.days
  policy.policy_start_date = Date.current + 10.days
  policy.policy_end_date = Date.current + 1.year + 10.days
  policy.payment_mode = 'Yearly'
  policy.sum_insured = 500000
  policy.net_premium = 12000
  policy.total_premium = 14160
  policy.gst_percentage = 18
  policy.is_customer_added = true
  policy.is_agent_added = false
  policy.is_admin_added = false
end

health_policy2 = HealthInsurance.find_or_create_by(policy_number: 'HEALTH002') do |policy|
  policy.customer = customer2
  policy.policy_holder = customer2.display_name
  policy.plan_name = 'Individual Health Cover'
  policy.insurance_company_name = 'Star Health'
  policy.insurance_type = 'Individual'
  policy.policy_type = 'New'
  policy.policy_booking_date = Date.current - 10.days
  policy.policy_start_date = Date.current + 15.days
  policy.policy_end_date = Date.current + 1.year + 15.days
  policy.payment_mode = 'Yearly'
  policy.sum_insured = 300000
  policy.net_premium = 8000
  policy.total_premium = 9440
  policy.gst_percentage = 18
  policy.is_customer_added = false
  policy.is_agent_added = true
  policy.is_admin_added = false
end

puts "✅ Health Insurance Policies created: #{HealthInsurance.count}"

# Create Motor Insurance Policies
puts "🚗 Creating Motor Insurance Policies..."

motor_policy1 = MotorInsurance.find_or_create_by(policy_number: 'MOTOR001') do |policy|
  policy.customer = customer1
  policy.policy_holder = customer1.display_name
  policy.insurance_company_name = 'ICICI Lombard'
  policy.policy_type = 'Comprehensive'
  policy.vehicle_type = 'Four Wheeler'
  policy.make = 'Maruti Suzuki'
  policy.model = 'Swift'
  policy.variant = 'VXI'
  policy.mfy = 2020
  policy.registration_number = 'MH12AB1234'
  policy.engine_number = 'ENG123456789'
  policy.chassis_number = 'CHA987654321'
  policy.vehicle_idv = 600000
  policy.policy_start_date = Date.current
  policy.policy_end_date = Date.current + 1.year
  policy.sum_insured = 600000
  policy.net_premium = 15000
  policy.total_premium = 17700
  policy.gst_percentage = 18
  policy.status = :active
end

motor_policy2 = MotorInsurance.find_or_create_by(policy_number: 'MOTOR002') do |policy|
  policy.customer = customer2
  policy.policy_holder = customer2.display_name
  policy.insurance_company_name = 'Bajaj Allianz'
  policy.policy_type = 'Third Party'
  policy.vehicle_type = 'Two Wheeler'
  policy.make = 'Honda'
  policy.model = 'Activa'
  policy.variant = '6G'
  policy.mfy = 2022
  policy.registration_number = 'KA05CD5678'
  policy.engine_number = 'ENG987654321'
  policy.chassis_number = 'CHA123456789'
  policy.vehicle_idv = 80000
  policy.policy_start_date = Date.current + 5.days
  policy.policy_end_date = Date.current + 1.year + 5.days
  policy.sum_insured = 80000
  policy.net_premium = 3000
  policy.total_premium = 3540
  policy.gst_percentage = 18
  policy.status = :active
end

puts "✅ Motor Insurance Policies created: #{MotorInsurance.count}"

# Display Summary
puts "\n" + "=" * 50
puts "🎉 MOCK DATA CREATION COMPLETE!"
puts "=" * 50

puts "\n📊 DATA SUMMARY:"
puts "-" * 30
puts "👥 Users: #{User.count}"
puts "   📧 Admin: admin@dhanvantri.com / admin123456"
puts "   👨‍💼 Sub-Agent: subagent@dhanvantri.com / subagent123456"
puts "   👤 Customer 1: customer1@example.com / customer123456"
puts "   👤 Customer 2: customer2@example.com / customer123456"
puts ""
puts "🏢 Organizations: #{SubAgent.count} Sub-Agents, #{Distributor.count} Distributors, #{Investor.count} Investors"
puts "👨‍👩‍👧‍👦 Customers: #{Customer.count}"
puts "🏛️ Agency Codes: #{AgencyCode.count}"
puts "🤝 Brokers: #{Broker.count}"
puts ""
puts "📋 Insurance Policies:"
puts "   🧬 Life Insurance: #{LifeInsurance.count}"
puts "   🏥 Health Insurance: #{HealthInsurance.count}"
puts "   🚗 Motor Insurance: #{MotorInsurance.count}"
puts ""
puts "⚙️ System Settings: Company Expenses = #{SystemSetting.company_expenses_percentage}%"

puts "\n🔑 KEY CREDENTIALS:"
puts "-" * 30
puts "Admin Login: admin@dhanvantri.com / admin123456"
puts "Sub-Agent Login: subagent@dhanvantri.com / subagent123456"
puts "Customer Login: customer1@example.com / customer123456"

puts "\n🚀 API TESTING READY!"
puts "You can now test your APIs with the above data."
puts "=" * 50