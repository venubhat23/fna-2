# Quick Test Data Generation for Mobile APIs
puts "🚀 Creating basic test data for Mobile APIs..."

begin
  # Create basic users if they don't exist
  admin = User.find_or_create_by(email: 'admin@example.com') do |user|
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.first_name = 'John'
    user.last_name = 'Doe'
    user.mobile = '9876543210'
    user.user_type = 'agent'
    user.role = 'admin_role'
    user.status = true
  end

  agent1 = User.find_or_create_by(email: 'agent1@example.com') do |user|
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.first_name = 'Jane'
    user.last_name = 'Smith'
    user.mobile = '9876543211'
    user.user_type = 'agent'
    user.role = 'agent_role'
    user.status = true
  end

  # Create basic customers
  customer1 = Customer.find_or_create_by(email: 'rajesh.kumar@example.com') do |customer|
    customer.customer_type = 'individual'
    customer.first_name = 'Rajesh'
    customer.last_name = 'Kumar'
    customer.mobile = '9876543217'
    customer.birth_date = '1985-05-15'
    customer.gender = 'Male'
    customer.address = '123 MG Road, Bangalore'
    customer.city = 'Bangalore'
    customer.state = 'Karnataka'
    customer.pincode = '560100'
    customer.pan_no = 'RAJESH123F'
    customer.occupation = 'Software Engineer'
    customer.annual_income = 1200000
    customer.marital_status = 'Married'
    customer.status = true
    customer.added_by = admin.id
  end

  customer2 = Customer.find_or_create_by(email: 'priya.sharma@example.com') do |customer|
    customer.customer_type = 'individual'
    customer.first_name = 'Priya'
    customer.last_name = 'Sharma'
    customer.mobile = '9876543218'
    customer.birth_date = '1988-08-20'
    customer.gender = 'Female'
    customer.address = '456 Park Street, Bangalore'
    customer.city = 'Bangalore'
    customer.state = 'Karnataka'
    customer.pincode = '560034'
    customer.pan_no = 'PRIYA5678G'
    customer.occupation = 'Marketing Manager'
    customer.annual_income = 800000
    customer.marital_status = 'Married'
    customer.status = true
    customer.added_by = agent1.id
  end

  puts "✅ Created users and customers"

  # Create basic sub agents
  sub_agent1 = SubAgent.find_or_create_by(email: 'rakesh.agent@example.com') do |sa|
    sa.first_name = 'Rakesh'
    sa.last_name = 'Patel'
    sa.mobile = '9876543213'
    sa.role_id = 1
    sa.status = 'active'
  end

  puts "✅ Created sub agents"

  # Create basic insurance companies
  InsuranceCompany.find_or_create_by(name: 'Star Health Insurance', status: true)
  InsuranceCompany.find_or_create_by(name: 'LIC of India', status: true)
  InsuranceCompany.find_or_create_by(name: 'HDFC ERGO Health Insurance', status: true)

  puts "✅ Created insurance companies"

  # Create basic brokers and agency codes
  broker = Broker.find_or_create_by(email: 'contact@primebrokers.com') do |b|
    b.company_name = 'Prime Insurance Brokers'
    b.contact_person = 'Rajesh Kumar'
    b.mobile = '9876543215'
    b.status = 'active'
  end

  agency_code = AgencyCode.find_or_create_by(agency_code: 'PA001') do |ac|
    ac.agency_name = 'Prime Agency'
    ac.contact_person = 'Suresh Reddy'
    ac.mobile = '9876543216'
    ac.email = 'agency@primeagency.com'
  end

  puts "✅ Created brokers and agency codes"

  # Create test policies only if customers exist
  if customer1 && sub_agent1 && agency_code && broker
    # Health Insurance
    health_policy = HealthInsurance.find_or_create_by(policy_number: 'SHP2025001') do |policy|
      policy.customer = customer1
      policy.sub_agent = sub_agent1
      policy.agency_code = agency_code
      policy.broker = broker
      policy.plan_name = 'Star Comprehensive Health Plan'
      policy.policy_holder = 'Rajesh Kumar'
      policy.insurance_company_name = 'Star Health Insurance'
      policy.insurance_type = 'Family Floater'
      policy.policy_type = 'New'
      policy.policy_start_date = '2025-01-01'
      policy.policy_end_date = '2025-12-31'
      policy.payment_mode = 'Yearly'
      policy.sum_insured = 500000.0
      policy.net_premium = 21186.0
      policy.gst_percentage = 18.0
      policy.total_premium = 25000.0
      policy.agent_commission_percentage = 10.0
      policy.commission_amount = 2500.0
      policy.status = 'active'
      policy.added_by = admin.id
    end

    # Life Insurance
    life_policy = LifeInsurance.find_or_create_by(policy_number: 'LIC2025001') do |policy|
      policy.customer = customer1
      policy.sub_agent = sub_agent1
      policy.agency_code = agency_code
      policy.broker = broker
      policy.plan_name = 'LIC Jeevan Anand'
      policy.policy_holder = 'Rajesh Kumar'
      policy.insurance_company_name = 'LIC of India'
      policy.policy_type = 'New'
      policy.policy_start_date = '2025-01-01'
      policy.policy_end_date = '2045-12-31'
      policy.payment_mode = 'Yearly'
      policy.policy_term = 20
      policy.premium_payment_term = 15
      policy.sum_insured = 1000000.0
      policy.net_premium = 42373.0
      policy.total_premium = 50000.0
      policy.nominee_name = 'Priya Kumar'
      policy.nominee_relationship = 'Spouse'
      policy.agent_commission_percentage = 10.0
      policy.commission_amount = 5000.0
      policy.status = 'active'
      policy.added_by = admin.id
    end

    puts "✅ Created test policies"
  end

  puts "\n🎉 BASIC TEST DATA COMPLETE!"
  puts "=" * 50
  puts "📊 SUMMARY:"
  puts "Users: #{User.count}"
  puts "Customers: #{Customer.count}"
  puts "Sub Agents: #{SubAgent.count}"
  puts "Health Policies: #{HealthInsurance.count}"
  puts "Life Policies: #{LifeInsurance.count}"

  puts "\n🔐 LOGIN CREDENTIALS:"
  puts "Admin: admin@example.com / password123"
  puts "Agent: agent1@example.com / password123"
  puts "Customer: rajesh.kumar@example.com / password123"
  puts "Sub Agent: rakesh.agent@example.com / password123"

  puts "\n🚀 Ready to test Mobile APIs!"

rescue => e
  puts "\n❌ ERROR: #{e.message}"
  puts "Please check and try again."
end