# Rails Console Mock Data Generation Commands

Run these commands in Rails console (`rails console` or `rails c`) to generate comprehensive mock data for testing all mobile APIs.

## 1. Create Admin/Agent Users

```ruby
# Create Admin User
admin = User.create!(
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'John',
  last_name: 'Doe',
  mobile: '9876543210',
  user_type: 'agent',
  agent_role: 'admin',
  status: true
)

# Create Agent User
agent1 = User.create!(
  email: 'agent1@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Jane',
  last_name: 'Smith',
  mobile: '9876543211',
  user_type: 'agent',
  agent_role: 'agent',
  status: true
)

# Create Agent User 2
agent2 = User.create!(
  email: 'agent2@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Michael',
  last_name: 'Johnson',
  mobile: '9876543212',
  user_type: 'agent',
  agent_role: 'agent',
  status: true
)

puts "✅ Created #{User.count} users"
```

## 2. Create Sub Agents

```ruby
# Create Sub Agents
sub_agent1 = SubAgent.create!(
  first_name: 'Rakesh',
  last_name: 'Patel',
  mobile: '9876543213',
  email: 'rakesh.agent@example.com',
  role_id: 1,
  gender: 'Male',
  birth_date: '1985-05-15',
  pan_no: 'AGENT1234F',
  address: '123 Agent Street, Mumbai',
  bank_name: 'SBI',
  account_no: '12345678901',
  ifsc_code: 'SBIN0000123',
  account_holder_name: 'Rakesh Patel',
  account_type: 'Savings',
  status: 'active'
)

sub_agent2 = SubAgent.create!(
  first_name: 'Priya',
  last_name: 'Sharma',
  mobile: '9876543214',
  email: 'priya.agent@example.com',
  role_id: 1,
  gender: 'Female',
  birth_date: '1990-08-20',
  pan_no: 'AGENT5678G',
  address: '456 Agent Road, Delhi',
  bank_name: 'HDFC',
  account_no: '98765432109',
  ifsc_code: 'HDFC0000456',
  account_holder_name: 'Priya Sharma',
  account_type: 'Current',
  status: 'active'
)

puts "✅ Created #{SubAgent.count} sub agents"
```

## 3. Create Insurance Companies and Brokers

```ruby
# Create Insurance Companies
insurance_companies = [
  { name: 'Star Health Insurance', address: 'Chennai, Tamil Nadu', phone: '044-12345678' },
  { name: 'LIC of India', address: 'Mumbai, Maharashtra', phone: '022-12345678' },
  { name: 'HDFC ERGO Health Insurance', address: 'Mumbai, Maharashtra', phone: '022-87654321' },
  { name: 'Bajaj Allianz General Insurance', address: 'Pune, Maharashtra', phone: '020-12345678' },
  { name: 'SBI Life Insurance', address: 'Mumbai, Maharashtra', phone: '022-11111111' },
  { name: 'ICICI Prudential Life Insurance', address: 'Mumbai, Maharashtra', phone: '022-22222222' }
].map do |company_data|
  InsuranceCompany.create!(company_data)
end

# Create Agency/Broker
broker = Broker.create!(
  company_name: 'Prime Insurance Brokers',
  contact_person: 'Rajesh Kumar',
  mobile: '9876543215',
  email: 'contact@primebrokers.com',
  address: '789 Broker Street, Bangalore',
  city: 'Bangalore',
  state: 'Karnataka',
  pincode: '560001',
  pan_no: 'BROKER123F',
  gst_no: 'GST123456789',
  status: 'active'
)

# Create Agency Code
agency_code = AgencyCode.create!(
  agency_name: 'Prime Agency',
  agency_code: 'PA001',
  contact_person: 'Suresh Reddy',
  mobile: '9876543216',
  email: 'agency@primeagency.com'
)

puts "✅ Created #{InsuranceCompany.count} insurance companies, #{Broker.count} brokers, #{AgencyCode.count} agency codes"
```

## 4. Create Individual Customers

```ruby
customers_data = [
  {
    customer_type: 'individual',
    first_name: 'Rajesh',
    last_name: 'Kumar',
    email: 'rajesh.kumar@example.com',
    mobile: '9876543217',
    birth_date: '1985-05-15',
    age: 38,
    gender: 'Male',
    address: '123 MG Road, Electronic City',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560100',
    pan_no: 'RAJESH123F',
    occupation: 'Software Engineer',
    annual_income: 1200000,
    marital_status: 'Married',
    education: 'Graduate',
    status: true,
    added_by: admin.id
  },
  {
    customer_type: 'individual',
    first_name: 'Priya',
    last_name: 'Sharma',
    email: 'priya.sharma@example.com',
    mobile: '9876543218',
    birth_date: '1988-08-20',
    age: 35,
    gender: 'Female',
    address: '456 Park Street, Koramangala',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560034',
    pan_no: 'PRIYA5678G',
    occupation: 'Marketing Manager',
    annual_income: 800000,
    marital_status: 'Married',
    education: 'Post Graduate',
    status: true,
    added_by: agent1.id
  },
  {
    customer_type: 'individual',
    first_name: 'Amit',
    last_name: 'Patel',
    email: 'amit.patel@example.com',
    mobile: '9876543219',
    birth_date: '1990-03-10',
    age: 33,
    gender: 'Male',
    address: '789 Ring Road, Marathahalli',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560037',
    pan_no: 'AMIT9012H',
    occupation: 'Business Owner',
    annual_income: 1500000,
    marital_status: 'Single',
    education: 'Graduate',
    status: true,
    added_by: agent2.id
  },
  {
    customer_type: 'individual',
    first_name: 'Suresh',
    last_name: 'Reddy',
    email: 'suresh.reddy@example.com',
    mobile: '9876543220',
    birth_date: '1982-12-25',
    age: 41,
    gender: 'Male',
    address: '321 Outer Ring Road, Whitefield',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560066',
    pan_no: 'SURESH34J',
    occupation: 'Consultant',
    annual_income: 1000000,
    marital_status: 'Married',
    education: 'Post Graduate',
    status: true,
    added_by: admin.id
  },
  {
    customer_type: 'individual',
    first_name: 'Anita',
    last_name: 'Singh',
    email: 'anita.singh@example.com',
    mobile: '9876543221',
    birth_date: '1992-06-18',
    age: 31,
    gender: 'Female',
    address: '654 Hosur Road, BTM Layout',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560029',
    pan_no: 'ANITA567K',
    occupation: 'Teacher',
    annual_income: 600000,
    marital_status: 'Single',
    education: 'Graduate',
    status: true,
    added_by: agent1.id
  }
]

customers = customers_data.map { |data| Customer.create!(data) }

puts "✅ Created #{customers.count} individual customers"
```

## 5. Create Corporate Customers

```ruby
corporate_customers_data = [
  {
    customer_type: 'corporate',
    company_name: 'Tech Solutions Pvt Ltd',
    first_name: 'Ravi',
    last_name: 'Gupta',
    email: 'ravi.gupta@techsolutions.com',
    mobile: '9876543222',
    birth_date: '1980-04-15',
    age: 43,
    gender: 'Male',
    address: '100 IT Park, Electronic City Phase 2',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560100',
    pan_no: 'RAVI1234L',
    gst_no: 'GST29RAVI1234L1ZS',
    occupation: 'CEO',
    annual_income: 2500000,
    marital_status: 'Married',
    education: 'Post Graduate',
    status: true,
    added_by: admin.id
  },
  {
    customer_type: 'corporate',
    company_name: 'Global Services Ltd',
    first_name: 'Meera',
    last_name: 'Nair',
    email: 'meera.nair@globalservices.com',
    mobile: '9876543223',
    birth_date: '1978-09-30',
    age: 45,
    gender: 'Female',
    address: '200 Business Park, Hebbal',
    city: 'Bangalore',
    state: 'Karnataka',
    pincode: '560024',
    pan_no: 'MEERA678M',
    gst_no: 'GST29MEERA678M1ZS',
    occupation: 'Director',
    annual_income: 3000000,
    marital_status: 'Married',
    education: 'Post Graduate',
    status: true,
    added_by: agent2.id
  }
]

corporate_customers = corporate_customers_data.map { |data| Customer.create!(data) }

puts "✅ Created #{corporate_customers.count} corporate customers"
```

## 6. Create Family Members

```ruby
# Add family members for individual customers
family_members_data = [
  # Rajesh Kumar's family
  {
    customer: customers[0],
    name: 'Priya Kumar',
    relationship: 'Spouse',
    birth_date: '1987-08-20',
    age: 36,
    gender: 'Female'
  },
  {
    customer: customers[0],
    name: 'Arjun Kumar',
    relationship: 'Son',
    birth_date: '2015-03-10',
    age: 8,
    gender: 'Male'
  },
  # Priya Sharma's family
  {
    customer: customers[1],
    name: 'Rahul Sharma',
    relationship: 'Spouse',
    birth_date: '1985-12-15',
    age: 38,
    gender: 'Male'
  },
  {
    customer: customers[1],
    name: 'Kavya Sharma',
    relationship: 'Daughter',
    birth_date: '2018-06-25',
    age: 5,
    gender: 'Female'
  },
  # Suresh Reddy's family
  {
    customer: customers[3],
    name: 'Lakshmi Reddy',
    relationship: 'Spouse',
    birth_date: '1985-02-14',
    age: 38,
    gender: 'Female'
  },
  {
    customer: customers[3],
    name: 'Kiran Reddy',
    relationship: 'Son',
    birth_date: '2012-11-08',
    age: 11,
    gender: 'Male'
  }
]

family_members = family_members_data.map { |data| FamilyMember.create!(data) }

puts "✅ Created #{family_members.count} family members"
```

## 7. Create Health Insurance Policies

```ruby
health_policies_data = [
  {
    customer: customers[0], # Rajesh Kumar
    sub_agent: sub_agent1,
    agency_code: agency_code,
    broker: broker,
    policy_number: 'SHP2025001',
    plan_name: 'Star Comprehensive Health Plan',
    policy_holder: 'Rajesh Kumar',
    insurance_company_name: 'Star Health Insurance',
    insurance_type: 'Family Floater',
    policy_type: 'New',
    policy_start_date: '2025-01-01',
    policy_end_date: '2025-12-31',
    payment_mode: 'Yearly',
    sum_insured: 500000.0,
    net_premium: 21186.0,
    gst_percentage: 18.0,
    gst_amount: 3813.48,
    total_premium: 25000.0,
    agent_commission_percentage: 10.0,
    commission_amount: 2500.0,
    tds_applicable: false,
    status: 'active',
    added_by: admin.id
  },
  {
    customer: customers[1], # Priya Sharma
    sub_agent: sub_agent2,
    agency_code: agency_code,
    broker: broker,
    policy_number: 'HHP2025002',
    plan_name: 'HDFC ERGO Health Suraksha',
    policy_holder: 'Priya Sharma',
    insurance_company_name: 'HDFC ERGO Health Insurance',
    insurance_type: 'Family Floater',
    policy_type: 'New',
    policy_start_date: '2025-02-01',
    policy_end_date: '2026-01-31',
    payment_mode: 'Yearly',
    sum_insured: 300000.0,
    net_premium: 16949.0,
    gst_percentage: 18.0,
    gst_amount: 3050.82,
    total_premium: 20000.0,
    agent_commission_percentage: 12.0,
    commission_amount: 2400.0,
    tds_applicable: false,
    status: 'active',
    added_by: agent1.id
  },
  {
    customer: customers[4], # Anita Singh
    sub_agent: sub_agent1,
    agency_code: agency_code,
    broker: broker,
    policy_number: 'SHP2025003',
    plan_name: 'Star Young Star Insurance',
    policy_holder: 'Anita Singh',
    insurance_company_name: 'Star Health Insurance',
    insurance_type: 'Individual',
    policy_type: 'New',
    policy_start_date: '2025-03-01',
    policy_end_date: '2026-02-28',
    payment_mode: 'Yearly',
    sum_insured: 200000.0,
    net_premium: 8475.0,
    gst_percentage: 18.0,
    gst_amount: 1525.5,
    total_premium: 10000.0,
    agent_commission_percentage: 15.0,
    commission_amount: 1500.0,
    tds_applicable: false,
    status: 'active',
    added_by: agent1.id
  }
]

health_policies = health_policies_data.map { |data| HealthInsurance.create!(data) }

puts "✅ Created #{health_policies.count} health insurance policies"
```

## 8. Create Life Insurance Policies

```ruby
life_policies_data = [
  {
    customer: customers[0], # Rajesh Kumar
    sub_agent: sub_agent1,
    agency_code: agency_code,
    broker: broker,
    policy_number: 'LIC2025001',
    plan_name: 'LIC Jeevan Anand',
    policy_holder: 'Rajesh Kumar',
    insurance_company_name: 'LIC of India',
    policy_type: 'New',
    policy_start_date: '2025-01-01',
    policy_end_date: '2045-12-31',
    payment_mode: 'Yearly',
    policy_term: 20,
    premium_payment_term: 15,
    sum_insured: 1000000.0,
    net_premium: 42373.0,
    total_premium: 50000.0,
    nominee_name: 'Priya Kumar',
    nominee_relationship: 'Spouse',
    agent_commission_percentage: 10.0,
    commission_amount: 5000.0,
    gst_1st_year: 18.0,
    gst_2nd_year: 18.0,
    gst_3rd_year: 18.0,
    bank_name: 'SBI',
    account_number: '12345678901',
    ifsc_code: 'SBIN0000123',
    status: 'active',
    added_by: admin.id
  },
  {
    customer: customers[1], # Priya Sharma
    sub_agent: sub_agent2,
    agency_code: agency_code,
    broker: broker,
    policy_number: 'SBI2025001',
    plan_name: 'SBI Life eShield Term Plan',
    policy_holder: 'Priya Sharma',
    insurance_company_name: 'SBI Life Insurance',
    policy_type: 'New',
    policy_start_date: '2025-02-01',
    policy_end_date: '2050-01-31',
    payment_mode: 'Yearly',
    policy_term: 25,
    premium_payment_term: 20,
    sum_insured: 2000000.0,
    net_premium: 16949.0,
    total_premium: 20000.0,
    nominee_name: 'Rahul Sharma',
    nominee_relationship: 'Spouse',
    agent_commission_percentage: 8.0,
    commission_amount: 1600.0,
    gst_1st_year: 18.0,
    gst_2nd_year: 18.0,
    gst_3rd_year: 18.0,
    bank_name: 'HDFC Bank',
    account_number: '98765432109',
    ifsc_code: 'HDFC0000456',
    status: 'active',
    added_by: agent1.id
  },
  {
    customer: customers[3], # Suresh Reddy
    sub_agent: sub_agent1,
    agency_code: agency_code,
    broker: broker,
    policy_number: 'ICICI2025001',
    plan_name: 'ICICI Prudential iProtect Smart',
    policy_holder: 'Suresh Reddy',
    insurance_company_name: 'ICICI Prudential Life Insurance',
    policy_type: 'New',
    policy_start_date: '2025-01-15',
    policy_end_date: '2040-01-14',
    payment_mode: 'Yearly',
    policy_term: 15,
    premium_payment_term: 15,
    sum_insured: 1500000.0,
    net_premium: 21186.0,
    total_premium: 25000.0,
    nominee_name: 'Lakshmi Reddy',
    nominee_relationship: 'Spouse',
    agent_commission_percentage: 12.0,
    commission_amount: 3000.0,
    gst_1st_year: 18.0,
    gst_2nd_year: 18.0,
    gst_3rd_year: 18.0,
    bank_name: 'ICICI Bank',
    account_number: '11223344556',
    ifsc_code: 'ICIC0000789',
    status: 'active',
    added_by: admin.id
  }
]

life_policies = life_policies_data.map { |data| LifeInsurance.create!(data) }

puts "✅ Created #{life_policies.count} life insurance policies"
```

## 9. Create Motor Insurance Policies

```ruby
# Create Motor Insurance Policies using the Policy model
motor_policies_data = [
  {
    customer: customers[2], # Amit Patel
    user: admin,
    insurance_company: insurance_companies[3], # Bajaj Allianz
    agency_broker: broker,
    policy_number: 'MOTOR2025001',
    plan_name: 'Comprehensive Car Insurance',
    insurance_type: 'motor',
    policy_type: 'new_policy',
    policy_start_date: '2025-01-01',
    policy_end_date: '2026-01-01',
    payment_mode: 'yearly',
    sum_insured: 800000.0,
    net_premium: 25424.0,
    gst_percentage: 18.0,
    total_premium: 30000.0,
    agent_commission_percentage: 15.0,
    commission_amount: 4500.0,
    status: true
  },
  {
    customer: customers[3], # Suresh Reddy
    user: agent2,
    insurance_company: insurance_companies[3], # Bajaj Allianz
    agency_broker: broker,
    policy_number: 'MOTOR2025002',
    plan_name: 'Two Wheeler Comprehensive Insurance',
    insurance_type: 'motor',
    policy_type: 'renewal',
    policy_start_date: '2025-02-01',
    policy_end_date: '2026-02-01',
    payment_mode: 'yearly',
    sum_insured: 150000.0,
    net_premium: 8475.0,
    gst_percentage: 18.0,
    total_premium: 10000.0,
    agent_commission_percentage: 20.0,
    commission_amount: 2000.0,
    status: true
  }
]

motor_policies = motor_policies_data.map { |data| Policy.create!(data) }

# Create Motor Insurance specific details
motor_insurance_details = [
  {
    policy: motor_policies[0],
    vehicle_make: 'Maruti Suzuki',
    vehicle_model: 'Swift VXI',
    vehicle_number: 'KA01AB1234',
    vehicle_year: 2022,
    engine_number: 'ENG123456789',
    chassis_number: 'CHA987654321',
    vehicle_type: 'Four Wheeler'
  },
  {
    policy: motor_policies[1],
    vehicle_make: 'Honda',
    vehicle_model: 'Activa 6G',
    vehicle_number: 'KA02CD5678',
    vehicle_year: 2021,
    engine_number: 'ENG987654321',
    chassis_number: 'CHA123456789',
    vehicle_type: 'Two Wheeler'
  }
]

motor_details = motor_insurance_details.map { |data| MotorInsurance.create!(data) }

puts "✅ Created #{motor_policies.count} motor insurance policies with details"
```

## 10. Create Other Insurance Policies

```ruby
# Create Other Insurance Policies using the Policy model
other_policies_data = [
  {
    customer: customers[3], # Suresh Reddy
    user: admin,
    insurance_company: insurance_companies[2], # HDFC ERGO
    agency_broker: broker,
    policy_number: 'TRAVEL2025001',
    plan_name: 'International Travel Insurance',
    insurance_type: 'other',
    policy_type: 'new_policy',
    policy_start_date: '2025-03-01',
    policy_end_date: '2026-03-01',
    payment_mode: 'yearly',
    sum_insured: 200000.0,
    net_premium: 8475.0,
    gst_percentage: 18.0,
    total_premium: 10000.0,
    agent_commission_percentage: 20.0,
    commission_amount: 2000.0,
    status: true
  },
  {
    customer: customers[4], # Anita Singh
    user: agent1,
    insurance_company: insurance_companies[2], # HDFC ERGO
    agency_broker: broker,
    policy_number: 'PROP2025001',
    plan_name: 'Home Insurance Premium',
    insurance_type: 'other',
    policy_type: 'new_policy',
    policy_start_date: '2025-01-15',
    policy_end_date: '2026-01-15',
    payment_mode: 'yearly',
    sum_insured: 500000.0,
    net_premium: 12712.0,
    gst_percentage: 18.0,
    total_premium: 15000.0,
    agent_commission_percentage: 15.0,
    commission_amount: 2250.0,
    status: true
  }
]

other_policies = other_policies_data.map { |data| Policy.create!(data) }

# Create Other Insurance specific details
other_insurance_details = [
  {
    policy: other_policies[0],
    coverage_type: 'Travel',
    description: 'Comprehensive international travel insurance with medical and baggage coverage'
  },
  {
    policy: other_policies[1],
    coverage_type: 'Property',
    description: 'Complete home insurance covering structure, contents, and personal belongings'
  }
]

other_details = other_insurance_details.map { |data| OtherInsurance.create!(data) }

puts "✅ Created #{other_policies.count} other insurance policies with details"
```

## 11. Summary and Verification

```ruby
# Print summary of created data
puts "\n" + "="*50
puts "MOCK DATA GENERATION COMPLETE"
puts "="*50

puts "👥 Users: #{User.count}"
puts "🏢 Sub Agents: #{SubAgent.count}"
puts "🏬 Insurance Companies: #{InsuranceCompany.count}"
puts "🤝 Brokers: #{Broker.count}"
puts "🏪 Agency Codes: #{AgencyCode.count}"
puts "👨‍👩‍👧‍👦 Customers: #{Customer.count}"
puts "   - Individual: #{Customer.where(customer_type: 'individual').count}"
puts "   - Corporate: #{Customer.where(customer_type: 'corporate').count}"
puts "👪 Family Members: #{FamilyMember.count}"
puts "🏥 Health Insurance: #{HealthInsurance.count}"
puts "👤 Life Insurance: #{LifeInsurance.count}"
puts "🚗 Motor Insurance: #{Policy.where(insurance_type: 'motor').count}"
puts "📋 Other Insurance: #{Policy.where(insurance_type: 'other').count}"

puts "\n📱 LOGIN CREDENTIALS FOR TESTING:"
puts "-" * 40
puts "ADMIN:"
puts "  Email: admin@example.com"
puts "  Password: password123"
puts "\nAGENTS:"
puts "  Email: agent1@example.com"
puts "  Password: password123"
puts "\n  Email: agent2@example.com"
puts "  Password: password123"
puts "\nSUB AGENTS:"
puts "  Email: rakesh.agent@example.com"
puts "  Password: password123"
puts "\n  Email: priya.agent@example.com"
puts "  Password: password123"
puts "\nCUSTOMERS:"
puts "  Email: rajesh.kumar@example.com"
puts "  Password: password123"
puts "\n  Email: priya.sharma@example.com"
puts "  Password: password123"

puts "\n🚀 Ready to test all Mobile API endpoints!"
puts "="*50
```

## 12. Quick Verification Queries

```ruby
# Quick verification queries to check data
puts "\n📊 QUICK DATA VERIFICATION:"
puts "-" * 30

# Check if customers have policies
customers_with_policies = Customer.joins("LEFT JOIN health_insurances ON customers.id = health_insurances.customer_id LEFT JOIN life_insurances ON customers.id = life_insurances.customer_id").where("health_insurances.id IS NOT NULL OR life_insurances.id IS NOT NULL").distinct.count

puts "Customers with policies: #{customers_with_policies}"

# Check policy counts by type
puts "Health policies: #{HealthInsurance.count}"
puts "Life policies: #{LifeInsurance.count}"
puts "Motor policies: #{Policy.where(insurance_type: 'motor').count}"
puts "Other policies: #{Policy.where(insurance_type: 'other').count}"

# Check total premium amounts
total_health_premium = HealthInsurance.sum(:total_premium)
total_life_premium = LifeInsurance.sum(:total_premium)
total_motor_premium = Policy.where(insurance_type: 'motor').sum(:total_premium)
total_other_premium = Policy.where(insurance_type: 'other').sum(:total_premium)

puts "\n💰 PREMIUM TOTALS:"
puts "Health: ₹#{total_health_premium.to_i}"
puts "Life: ₹#{total_life_premium.to_i}"
puts "Motor: ₹#{total_motor_premium.to_i}"
puts "Other: ₹#{total_other_premium.to_i}"
puts "GRAND TOTAL: ₹#{(total_health_premium + total_life_premium + total_motor_premium + total_other_premium).to_i}"

# Check commission amounts
total_health_commission = HealthInsurance.sum(:commission_amount)
total_life_commission = LifeInsurance.sum(:commission_amount)
total_motor_commission = Policy.where(insurance_type: 'motor').sum(:commission_amount)
total_other_commission = Policy.where(insurance_type: 'other').sum(:commission_amount)

puts "\n💼 COMMISSION TOTALS:"
puts "Health: ₹#{total_health_commission.to_i}"
puts "Life: ₹#{total_life_commission.to_i}"
puts "Motor: ₹#{total_motor_commission.to_i}"
puts "Other: ₹#{total_other_commission.to_i}"
puts "TOTAL COMMISSION: ₹#{(total_health_commission + total_life_commission + total_motor_commission + total_other_commission).to_i}"
```

## 13. One-Line Complete Setup

```ruby
# Run this single command to execute all the above commands at once
load Rails.root.join('db', 'seeds.rb') # If you put all the above in seeds.rb
# OR copy and paste all the above commands in rails console
```

---

## Usage Instructions

1. **Open Rails Console:**
   ```bash
   cd /path/to/drwise_admin
   rails console
   ```

2. **Copy and paste each section** above in order, or create a seed file with all the commands.

3. **Verify the data** using the verification queries.

4. **Test the APIs** using the provided Postman collection with the generated login credentials.

This will create a comprehensive dataset with:
- 3 Admin/Agent users
- 2 Sub agents
- 7 Customers (5 individual, 2 corporate)
- 6+ Family members
- 6 Insurance companies
- 1 Broker and Agency code
- 3 Health insurance policies
- 3 Life insurance policies
- 2 Motor insurance policies
- 2 Other insurance policies

**Total: 10+ policies across all insurance types with realistic data for complete API testing!**