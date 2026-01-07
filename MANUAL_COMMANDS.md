# Manual Commands for Mock Data Generation

Since there are some model issues with the automated script, you can run these commands manually in Rails console:

## Start Rails Console
```bash
RAILS_ENV=development bundle exec rails console
```

## Then run these commands one by one:

### 1. Create Admin User
```ruby
admin = User.find_or_create_by(email: 'admin@drwise.com') do |u|
  u.first_name = 'Admin'
  u.last_name = 'User'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.mobile = '+919999999999'
  u.pan_number = 'ADMIN1234A'
  u.date_of_birth = '1980-01-01'
  u.gender = 'male'
  u.occupation = 'Administrator'
  u.annual_income = 1000000
  u.address = 'Admin Office, Mumbai'
  u.state = 'Maharashtra'
  u.city = 'Mumbai'
  u.user_type = 'admin'
  u.status = true
end

puts "✅ Admin user: #{admin.email} / password123"
```

### 2. Create Some Customers
```ruby
5.times do |i|
  customer = Customer.find_or_create_by(email: "testcustomer#{i+1}@example.com") do |c|
    c.customer_type = 'individual'
    c.first_name = "Customer#{i+1}"
    c.last_name = "Test"
    c.mobile = "9#{100000000 + i}"
    c.gender = 'male'
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
```

### 3. Create Simple Health Insurance Policies
```ruby
Customer.limit(3).each_with_index do |customer, i|
  policy_number = "HI2025TEST#{i+1}"

  next if HealthInsurance.exists?(policy_number: policy_number)

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
    is_customer_added: true
  )
  puts "✅ Health Policy: #{policy.policy_number}"
end
```

### 4. Create Simple Life Insurance Policies
```ruby
Customer.limit(3).each_with_index do |customer, i|
  policy_number = "LI2025TEST#{i+1}"

  next if LifeInsurance.exists?(policy_number: policy_number)

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
    is_customer_added: true
  )
  puts "✅ Life Policy: #{policy.policy_number}"
end
```

### 5. Check Results
```ruby
puts "\n📊 SUMMARY:"
puts "👤 Admin Users: #{User.where(user_type: 'admin').count}"
puts "🏢 Sub Agents: #{SubAgent.count}"
puts "👥 Customers: #{Customer.count}"
puts "🏥 Health Insurance Policies: #{HealthInsurance.count}"
puts "💰 Life Insurance Policies: #{LifeInsurance.count}"

puts "\n🔑 LOGIN CREDENTIALS:"
puts "Admin Email: admin@drwise.com"
puts "Password: password123"
```

## Alternative: Create Agent User for API Testing
```ruby
agent = User.find_or_create_by(email: 'agent@drwise.com') do |u|
  u.first_name = 'Test'
  u.last_name = 'Agent'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.mobile = '+919888888888'
  u.pan_number = 'AGENT1234B'
  u.date_of_birth = '1985-01-01'
  u.gender = 'male'
  u.occupation = 'Insurance Agent'
  u.annual_income = 500000
  u.address = 'Agent Office, Delhi'
  u.state = 'Delhi'
  u.city = 'Delhi'
  u.user_type = 'agent'
  u.status = true
end

puts "✅ Agent user: #{agent.email} / password123"
```

This will give you basic data to test the mobile APIs!