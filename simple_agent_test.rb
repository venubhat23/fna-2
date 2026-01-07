#!/usr/bin/env ruby
puts "=== Setting up Agent Test Data ==="

# Use existing agent
agent_email = "test@example.com"  # Existing agent from database
agent_password = "TestAgent123!"

# Get existing agent user
agent_user = User.find_by(email: agent_email)
if agent_user
  puts "Using existing agent user: #{agent_email}"
  # Update password to known value
  agent_user.update!(password: agent_password, password_confirmation: agent_password)
  puts "Updated agent password to: #{agent_password}"
else
  puts "Agent user not found!"
  exit 1
end

# Get SubAgent record
sub_agent = SubAgent.find_by(email: agent_email)
if sub_agent
  puts "Using existing SubAgent: #{sub_agent.display_name} (ID: #{sub_agent.id})"
else
  puts "SubAgent not found!"
  exit 1
end

# Create 3 customers for this agent with simple data
3.times do |i|
  customer_email = "agenttestcust#{i+1}@test.com"
  customer = Customer.find_by(email: customer_email)

  unless customer
    customer = Customer.create!(
      customer_type: "individual",
      first_name: "TestCustomer#{i+1}",
      last_name: "Agent",
      email: customer_email,
      mobile: "98888888#{10+i}",
      added_by: sub_agent.id.to_s,
      status: true
    )
    puts "Created Customer: #{customer.display_name} (#{customer.email})"

    # Create User record for customer login - simplified
    customer_password = "Test123!"
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
      plan_name: "Test Health Plan #{i+1}",
      insurance_company_name: "Test Insurance Co",
      policy_type: "New",
      policy_number: "TEST-H#{(1000 + i)}",
      policy_start_date: Date.current - 30.days,
      policy_end_date: Date.current + 335.days,
      payment_mode: ["Monthly", "Quarterly", "Yearly"][i],
      sum_insured: 500000 + (i * 250000),
      net_premium: 15000 + (i * 5000),
      total_premium: 17700 + (i * 5900),
      gst_percentage: 18,
      installment_autopay_start_date: Date.current - (20 - i*7).days
    )
    puts "  Health Insurance: #{health_insurance.plan_name} (₹#{health_insurance.total_premium})"

    # Create Life Insurance for each customer
    life_insurance = LifeInsurance.create!(
      customer_id: customer.id,
      policy_holder: customer.display_name,
      plan_name: "Test Life Plan #{i+1}",
      insurance_company_name: "Test Life Co",
      policy_type: "New",
      policy_number: "TEST-L#{(2000 + i)}",
      policy_start_date: Date.current - 60.days,
      policy_end_date: Date.current + 20.years,
      payment_mode: ["Yearly", "Half-Yearly", "Monthly"][i],
      sum_insured: 1500000 + (i * 500000),
      net_premium: 45000 + (i * 10000),
      total_premium: 53100 + (i * 11800),
      policy_term: 20,
      premium_payment_term: 15,
      nominee_name: "Test Nominee #{i+1}",
      nominee_relationship: "Spouse",
      installment_autopay_start_date: Date.current - (40 - i*10).days
    )
    puts "  Life Insurance: #{life_insurance.plan_name} (₹#{life_insurance.total_premium})"
  else
    puts "Customer already exists: #{customer.display_name}"
  end
end

puts "\n" + "="*50
puts "🎯 AGENT TEST ACCOUNT READY!"
puts "="*50
puts ""
puts "🔑 AGENT LOGIN CREDENTIALS:"
puts "  📧 Email: #{agent_email}"
puts "  🔐 Password: #{agent_password}"
puts "  🆔 Agent ID: #{sub_agent.id}"
puts ""

# Get agent's customers and their data
agent_customers = Customer.where(added_by: sub_agent.id.to_s)
puts "👥 CUSTOMERS (#{agent_customers.count}):"
agent_customers.each_with_index do |customer, i|
  puts "  #{i+1}. #{customer.display_name}"
  puts "     📧 Email: #{customer.email}"
  puts "     🔐 Password: Test123!"

  health_count = HealthInsurance.where(customer_id: customer.id).count
  life_count = LifeInsurance.where(customer_id: customer.id).count
  puts "     📊 Policies: #{health_count} Health + #{life_count} Life"
  puts ""
end

puts "🌐 API TESTING COMMANDS:"
puts ""
puts "# 1. Agent Login:"
puts "curl -X POST -H \"Content-Type: application/json\" \\"
puts "  -d '{\"email\":\"#{agent_email}\",\"password\":\"#{agent_password}\"}' \\"
puts "  http://localhost:3000/api/v1/agent/auth/login"
puts ""
puts "# 2. Customer Login (Customer 1):"
puts "curl -X POST -H \"Content-Type: application/json\" \\"
puts "  -d '{\"username\":\"agenttestcust1@test.com\",\"password\":\"Test123!\"}' \\"
puts "  http://localhost:3000/api/v1/mobile/auth/login"
puts ""
puts "✅ Ready to test all agent and customer mobile APIs!"

# Summary stats
total_health = HealthInsurance.joins(:customer).where(customers: {added_by: sub_agent.id.to_s}).count
total_life = LifeInsurance.joins(:customer).where(customers: {added_by: sub_agent.id.to_s}).count
total_customers = agent_customers.count

puts ""
puts "📊 SUMMARY:"
puts "  👨‍💼 Agent: #{sub_agent.display_name}"
puts "  👥 Customers: #{total_customers}"
puts "  🏥 Health Policies: #{total_health}"
puts "  💰 Life Policies: #{total_life}"
puts "  📋 Total Policies: #{total_health + total_life}"