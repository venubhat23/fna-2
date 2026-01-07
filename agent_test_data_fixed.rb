#!/usr/bin/env ruby
puts "=== Creating Comprehensive Agent Test Data ==="

# Create an agent user with login credentials
agent_email = "testagent@insurance.com"
agent_password = "Agent123!"

# Check if agent user already exists, if not create one
agent_user = User.find_by(email: agent_email)
if agent_user
  puts "Agent user already exists: #{agent_email}"
else
  agent_user = User.create!(
    first_name: "Test",
    last_name: "Agent",
    email: agent_email,
    mobile: "9999888777",
    password: agent_password,
    password_confirmation: agent_password,
    user_type: "agent",
    role: "agent_role",
    status: true
  )
  puts "Created agent user: #{agent_email} with password: #{agent_password}"
end

# Create or find SubAgent record
sub_agent = SubAgent.find_by(email: agent_email)
if sub_agent
  puts "SubAgent already exists: #{sub_agent.display_name}"
else
  sub_agent = SubAgent.create!(
    first_name: "Test",
    last_name: "Agent",
    middle_name: "Mobile",
    email: agent_email,
    mobile: "9999888777",
    role_id: 1,
    status: "active",
    gender: "Male",
    date_of_birth: 30.years.ago,
    address: "123 Insurance Street, Mumbai",
    city: "Mumbai",
    state: "Maharashtra",
    pincode: "400001",
    pan_number: "AGENT1234P",
    aadhar_number: "123456789012",
    account_number: "1234567890123456",
    ifsc_code: "HDFC0001234",
    account_type: "Savings",
    bank_name: "HDFC Bank",
    branch: "Mumbai Main"
  )
  puts "Created SubAgent: #{sub_agent.display_name}"
end

# Create 3 customers for this agent
3.times do |i|
  customer_email = "customer#{i+1}@agent.com"
  customer = Customer.find_by(email: customer_email)

  unless customer
    customer = Customer.create!(
      customer_type: "individual",
      first_name: "Agent Customer #{i+1}",
      last_name: "Test",
      email: customer_email,
      mobile: "98765432#{10+i}",
      added_by: sub_agent.id.to_s,
      status: true,
      age: 30 + i*5,
      gender: i.even? ? "male" : "female",
      address: "Customer #{i+1} Address",
      city: "Mumbai",
      state: "Maharashtra",
      pincode: "400002"
    )
    puts "Created Customer: #{customer.display_name} (#{customer.email})"

    # Create User record for customer login
    customer_password = "Customer#{i+1}@123"
    begin
      customer_user = User.create!(
        first_name: customer.first_name,
        last_name: customer.last_name,
        email: customer_email,
        mobile: customer.mobile,
        password: customer_password,
        password_confirmation: customer_password,
        user_type: "customer",
        role: "agent_role",
        status: true
      )
      puts "  Customer login: #{customer_email} / #{customer_password}"
    rescue => e
      puts "  Customer user creation failed: #{e.message}"
    end

    # Create Health Insurance for each customer
    health_insurance = HealthInsurance.create!(
      customer_id: customer.id,
      policy_holder: customer.display_name,
      plan_name: ["Star Health Comprehensive", "HDFC Ergo Health", "ICICI Lombard Health"][i],
      insurance_company_name: ["Star Health Insurance", "HDFC ERGO", "ICICI Lombard"][i],
      policy_type: "New",
      policy_number: "AGNT-HLT#{(1000 + i).to_s.rjust(6, '0')}",
      policy_start_date: Date.current - rand(30..90).days,
      policy_end_date: (Date.current - rand(30..90).days) + 1.year,
      payment_mode: ["Monthly", "Quarterly", "Half-Yearly"][i],
      sum_insured: [500000, 1000000, 750000][i],
      net_premium: [15000, 25000, 20000][i],
      total_premium: [17700, 29500, 23600][i],
      gst_percentage: 18,
      status: "active",
      added_by: sub_agent.id.to_s,
      installment_autopay_start_date: Date.current - (30 - i*10).days
    )
    puts "  Created Health Insurance: #{health_insurance.plan_name} (₹#{health_insurance.total_premium})"

    # Create Life Insurance for each customer
    life_insurance = LifeInsurance.create!(
      customer_id: customer.id,
      policy_holder: customer.display_name,
      plan_name: ["LIC Jeevan Anand", "HDFC Click 2 Protect", "SBI eShield"][i],
      insurance_company_name: ["LIC of India", "HDFC Life", "SBI Life"][i],
      policy_type: "New",
      policy_number: "AGNT-LIF#{(2000 + i).to_s.rjust(6, '0')}",
      policy_start_date: Date.current - rand(60..120).days,
      policy_end_date: (Date.current - rand(60..120).days) + 20.years,
      payment_mode: ["Yearly", "Half-Yearly", "Monthly"][i],
      sum_insured: [2000000, 1500000, 2500000][i],
      net_premium: [50000, 35000, 60000][i],
      total_premium: [59000, 41300, 70800][i],
      policy_term: 20,
      premium_payment_term: 15,
      nominee_name: "#{customer.first_name} Spouse",
      nominee_relationship: "Spouse",
      status: "active",
      added_by: sub_agent.id.to_s,
      installment_autopay_start_date: Date.current - (60 - i*15).days
    )
    puts "  Created Life Insurance: #{life_insurance.plan_name} (₹#{life_insurance.total_premium})"
  else
    puts "Customer already exists: #{customer.display_name}"
  end
end

puts "\n=== Agent Test Account Summary ==="
puts "🔑 AGENT LOGIN CREDENTIALS:"
puts "  📧 Email: #{agent_email}"
puts "  🔐 Password: #{agent_password}"
puts "  👤 Role: agent_role"
puts ""
puts "📊 Agent Details:"
puts "  👨‍💼 Name: #{sub_agent.display_name}"
puts "  📱 Mobile: #{sub_agent.mobile}"
puts "  🆔 SubAgent ID: #{sub_agent.id}"
puts ""
puts "👥 Customers under this agent:"
agent_customers = Customer.where(added_by: sub_agent.id.to_s)
agent_customers.each_with_index do |customer, i|
  puts "  #{i+1}. 👤 #{customer.display_name} (#{customer.email})"
  puts "     🔐 Login: #{customer.email} / Customer#{i+1}@123"

  health_count = HealthInsurance.where(customer_id: customer.id).count
  life_count = LifeInsurance.where(customer_id: customer.id).count
  puts "     🏥 Health Insurance: #{health_count} policies"
  puts "     💰 Life Insurance: #{life_count} policies"

  # Show upcoming installments for this customer
  upcoming_health = HealthInsurance.where(customer_id: customer.id)
    .where.not(installment_autopay_start_date: nil)
    .where('installment_autopay_start_date + INTERVAL \'1 month\' <= ?', 30.days.from_now)

  upcoming_life = LifeInsurance.where(customer_id: customer.id)
    .where.not(installment_autopay_start_date: nil)
    .where('installment_autopay_start_date + INTERVAL \'6 months\' <= ?', 30.days.from_now)

  total_upcoming = upcoming_health.count + upcoming_life.count
  if total_upcoming > 0
    puts "     ⏰ Upcoming installments: #{total_upcoming}"
  end
  puts ""
end

puts "📱 API Testing Information:"
puts ""
puts "🌐 Base URL: http://localhost:3000"
puts ""
puts "🔐 Agent API Endpoints:"
puts "  • Login: POST /api/v1/agent/auth/login"
puts "  • Dashboard: GET /api/v1/agent/dashboard"
puts "  • Customers: GET /api/v1/agent/customers"
puts "  • Policies: GET /api/v1/agent/policies"
puts ""
puts "📱 Customer Mobile API Endpoints:"
puts "  • Login: POST /api/v1/mobile/auth/login"
puts "  • Portfolio: GET /api/v1/mobile/customer/portfolio"
puts "  • Upcoming Installments: GET /api/v1/mobile/customer/upcoming_installments"
puts "  • Upcoming Renewals: GET /api/v1/mobile/customer/upcoming_renewals"
puts ""
puts "✅ Ready for comprehensive API testing!"
puts ""
puts "💡 Quick Test Commands:"
puts "# Agent Login:"
puts "curl -X POST -H \"Content-Type: application/json\" \\"
puts "  -d '{\"email\":\"#{agent_email}\",\"password\":\"#{agent_password}\"}' \\"
puts "  http://localhost:3000/api/v1/agent/auth/login"
puts ""
puts "# Customer Login (Customer 1):"
puts "curl -X POST -H \"Content-Type: application/json\" \\"
puts "  -d '{\"username\":\"customer1@agent.com\",\"password\":\"Customer1@123\"}' \\"
puts "  http://localhost:3000/api/v1/mobile/auth/login"

# Show total summary
total_customers = Customer.where(added_by: sub_agent.id.to_s).count
total_health_policies = HealthInsurance.joins(:customer).where(customers: {added_by: sub_agent.id.to_s}).count
total_life_policies = LifeInsurance.joins(:customer).where(customers: {added_by: sub_agent.id.to_s}).count

puts ""
puts "📊 FINAL SUMMARY:"
puts "  👨‍💼 Agent: #{sub_agent.display_name}"
puts "  👥 Total Customers: #{total_customers}"
puts "  🏥 Total Health Policies: #{total_health_policies}"
puts "  💰 Total Life Policies: #{total_life_policies}"
puts "  📝 Total Policies: #{total_health_policies + total_life_policies}"