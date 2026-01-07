# Simple Test Data Generation Script - No External Dependencies
# Run this in Rails console with: load 'db/simple_seed_data.rb'

puts "🚀 Starting simple test data generation (no Faker dependency)..."

# Sample data arrays
FIRST_NAMES = ['Rajesh', 'Priya', 'Amit', 'Sunita', 'Vikash', 'Neha', 'Suresh', 'Kavita', 'Arjun', 'Pooja',
               'Ravi', 'Sita', 'Karan', 'Meera', 'Anil', 'Geeta', 'Rohit', 'Radha', 'Sanjay', 'Usha']

LAST_NAMES = ['Sharma', 'Patel', 'Singh', 'Kumar', 'Agarwal', 'Gupta', 'Jain', 'Shah', 'Reddy', 'Rao',
              'Nair', 'Iyer', 'Verma', 'Chopra', 'Malhotra', 'Bansal', 'Mittal', 'Sinha', 'Mishra', 'Tiwari']

CITIES = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad', 'Pune', 'Ahmedabad', 'Jaipur', 'Surat',
          'Lucknow', 'Kanpur', 'Nagpur', 'Indore', 'Thane', 'Bhopal', 'Visakhapatnam', 'Pimpri', 'Patna', 'Vadodara']

STATES = ['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu', 'West Bengal', 'Telangana', 'Gujarat', 'Rajasthan',
          'Uttar Pradesh', 'Madhya Pradesh', 'Bihar', 'Andhra Pradesh', 'Odisha', 'Punjab', 'Haryana', 'Kerala']

COMPANY_NAMES = ['TechCorp Solutions', 'Global Enterprises', 'Apex Industries', 'Prime Ventures', 'Excel Corp',
                 'Summit Holdings', 'Vista Group', 'Alpha Systems', 'Beta Solutions', 'Gamma Industries']

INSURANCE_COMPANIES = ['ICICI Lombard', 'HDFC ERGO', 'Bajaj Allianz', 'IFFCO Tokio', 'Reliance General',
                       'SBI General', 'New India Assurance', 'Oriental Insurance', 'United India Insurance',
                       'National Insurance', 'Cholamandalam MS', 'Future Generali', 'Liberty General',
                       'Shriram Insurance', 'Digit Insurance']

CAR_MAKES = ['Maruti', 'Hyundai', 'Honda', 'Toyota', 'Tata', 'Mahindra', 'Ford', 'Volkswagen']
BIKE_MAKES = ['Hero', 'Bajaj', 'TVS', 'Honda', 'Yamaha', 'Royal Enfield', 'KTM', 'Suzuki']

# Helper methods
def random_name
  "#{FIRST_NAMES.sample} #{LAST_NAMES.sample}"
end

def random_email(name = nil)
  name ||= random_name.downcase.gsub(' ', '')
  domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com']
  "#{name}#{rand(100..999)}@#{domains.sample}"
end

def random_mobile
  "+91#{rand(7000000000..9999999999)}"
end

def random_pan
  letters = ('A'..'Z').to_a
  "#{letters.sample}#{letters.sample}#{letters.sample}#{letters.sample}#{letters.sample}#{rand(1000..9999)}#{letters.sample}"
end

def random_date_between(start_date, end_date)
  start_date + rand((end_date - start_date).to_i)
end

def random_address
  "#{rand(1..999)} #{['MG Road', 'Park Street', 'Main Road', 'Gandhi Nagar', 'City Center'].sample}, #{CITIES.sample}"
end

# Note: This script will add NEW data without clearing existing records
puts "📝 Adding new test data to existing records..."

# 1. Create Users (50 total)
puts "👥 Creating Users..."
# Get existing counts for unique numbering
existing_admin_count = User.where(user_type: 'admin').count
existing_agent_count = User.where(user_type: 'agent').count
existing_customer_count = User.where(user_type: 'customer').count

admins = 5.times.map do |i|
  User.create!(
    first_name: FIRST_NAMES[i],
    last_name: LAST_NAMES[i],
    email: "admin#{existing_admin_count + i + 1}@drwise.com",
    password: 'password123',
    mobile: random_mobile,
    user_type: 'admin',
    role: 'super_admin',
    status: true
  )
end

agents = 20.times.map do |i|
  User.create!(
    first_name: FIRST_NAMES[i % FIRST_NAMES.length],
    last_name: LAST_NAMES[i % LAST_NAMES.length],
    email: "agent#{existing_agent_count + i + 1}@drwise.com",
    password: 'password123',
    mobile: random_mobile,
    user_type: 'agent',
    role: 'agent_role',
    status: true
  )
end

customers_users = 25.times.map do |i|
  User.create!(
    first_name: FIRST_NAMES[i % FIRST_NAMES.length],
    last_name: LAST_NAMES[i % LAST_NAMES.length],
    email: "customer#{existing_customer_count + i + 1}@drwise.com",
    password: 'password123',
    mobile: random_mobile,
    user_type: 'customer',
    role: 'user_role',
    status: true
  )
end
puts "   ✅ Created #{User.count} users"

# 2. Create Customers (100 records)
puts "👨‍👩‍👧‍👦 Creating Customers..."
customers = 100.times.map do |i|
  name_parts = random_name.split
  Customer.create!(
    first_name: name_parts[0],
    last_name: name_parts[1],
    mobile: random_mobile,
    email: random_email,
    pan_no: random_pan,
    aadhar_no: rand(100000000000..999999999999).to_s,
    birth_date: random_date_between(50.years.ago, 18.years.ago),
    gender: %w[Male Female].sample,
    address: random_address,
    city: CITIES.sample,
    state: STATES.sample,
    pincode: rand(100000..999999).to_s,
    marital_status: %w[Single Married Divorced Widowed].sample,
    occupation: ['Engineer', 'Doctor', 'Teacher', 'Business', 'Lawyer', 'Accountant'].sample,
    annual_income: [300000, 500000, 800000, 1200000, 1500000, 2000000].sample,
    nominee_name: random_name,
    nominee_relationship: %w[Spouse Child Parent Sibling].sample,
    bank_name: ['SBI', 'HDFC', 'ICICI', 'Axis', 'PNB', 'BOB'].sample + ' Bank',
    account_no: rand(10000000000..99999999999).to_s,
    ifsc_code: ['SBIN', 'HDFC', 'ICIC', 'UTIB'].sample + rand(1000000..9999999).to_s[0..6],
    account_holder_name: random_name,
    status: true
  )
end
puts "   ✅ Created #{Customer.count} customers"

# 3. Create Insurance Companies (only if they don't exist)
puts "🏛️ Creating Insurance Companies..."
insurance_companies = []
INSURANCE_COMPANIES.each do |name|
  existing_company = InsuranceCompany.find_by(name: name)
  if existing_company
    insurance_companies << existing_company
  else
    insurance_companies << InsuranceCompany.create!(
      name: name,
      address: random_address,
      contact_number: random_mobile,
      email: "contact@#{name.downcase.gsub(/\s+/, '')}.com",
      website: "www.#{name.downcase.gsub(/\s+/, '')}.com",
      license_number: "LIC#{rand(10000000..99999999)}",
      status: true
    )
  end
end
puts "   ✅ Total insurance companies: #{InsuranceCompany.count}"

# 4. Create Distributors (15 records)
puts "🏢 Creating Distributors..."
existing_distributor_count = Distributor.count
distributors = 15.times.map do |i|
  name_parts = random_name.split
  Distributor.create!(
    first_name: name_parts[0],
    last_name: name_parts[1],
    company_name: COMPANY_NAMES[i % COMPANY_NAMES.length],
    mobile: random_mobile,
    email: "dist#{existing_distributor_count + i + 1}@drwise.com",
    pan_no: random_pan,
    gst_no: "#{rand(10..35)}#{random_pan}#{rand(1..9)}Z#{rand(1..9)}",
    address: random_address,
    city: CITIES.sample,
    state: STATES.sample,
    pincode: rand(100000..999999).to_s,
    bank_name: ['SBI', 'HDFC', 'ICICI'].sample + ' Bank',
    account_no: rand(10000000000..99999999999).to_s,
    ifsc_code: ['SBIN', 'HDFC', 'ICIC'].sample + rand(1000000).to_s,
    commission_percentage: [2.0, 2.5, 3.0, 3.5, 4.0].sample,
    status: true,
    affiliate_count: rand(5..15)
  )
end
puts "   ✅ Created #{Distributor.count} distributors"

# 5. Create Sub Agents (40 records)
puts "🤝 Creating Sub Agents..."
existing_subagent_count = SubAgent.count
# Use existing distributors if available, otherwise use the newly created ones
all_distributors = Distributor.all.to_a
all_distributors += distributors if distributors.any?

sub_agents = 40.times.map do |i|
  name_parts = random_name.split
  SubAgent.create!(
    first_name: name_parts[0],
    last_name: name_parts[1],
    mobile: random_mobile,
    email: "subagent#{existing_subagent_count + i + 1}@drwise.com",
    pan_no: random_pan,
    aadhar_no: rand(100000000000..999999999999).to_s,
    birth_date: random_date_between(45.years.ago, 21.years.ago),
    gender: %w[Male Female].sample,
    address: random_address,
    city: CITIES.sample,
    state: STATES.sample,
    bank_name: ['SBI', 'HDFC', 'ICICI'].sample + ' Bank',
    account_no: rand(10000000000..99999999999).to_s,
    ifsc_code: ['SBIN', 'HDFC', 'ICIC'].sample + rand(1000000).to_s,
    distributor: all_distributors.sample,
    status: true,
    password: 'password123'
  )
end
puts "   ✅ Created #{SubAgent.count} sub agents"

# 6. Create Investors (20 records)
puts "💼 Creating Investors..."
existing_investor_count = Investor.count
investors = 20.times.map do |i|
  name_parts = random_name.split
  Investor.create!(
    first_name: name_parts[0],
    last_name: name_parts[1],
    mobile: random_mobile,
    email: "investor#{existing_investor_count + i + 1}@drwise.com",
    birth_date: random_date_between(50.years.ago, 25.years.ago),
    gender: %w[Male Female].sample,
    pan_no: random_pan,
    gst_no: rand(2) == 0 ? "#{rand(10..35)}#{random_pan}#{rand(1..9)}Z#{rand(1..9)}" : nil,
    company_name: rand(2) == 0 ? COMPANY_NAMES.sample : nil,
    address: random_address,
    bank_name: ['SBI', 'HDFC', 'ICICI'].sample + ' Bank',
    account_no: rand(10000000000..99999999999).to_s,
    ifsc_code: ['SBIN', 'HDFC', 'ICIC'].sample + rand(1000000).to_s,
    account_holder_name: random_name,
    account_type: %w[Savings Current].sample,
    upi_id: "#{name_parts[0].downcase}#{rand(100)}@#{['paytm', 'phonepe', 'gpay'].sample}",
    status: 1
  )
end
puts "   ✅ Created #{Investor.count} investors"

# 7. Create Leads (150 records)
puts "🎯 Creating Leads..."
existing_lead_count = Lead.count
# Get all existing data to reference
all_customers = Customer.all.to_a
all_agents = User.where(user_type: 'agent').to_a
all_agents += agents if agents.any?

leads = 150.times.map do |i|
  name_parts = random_name.split
  lead = Lead.create!(
    lead_id: "LEAD2024#{sprintf('%06d', existing_lead_count + i + 1)}",
    first_name: name_parts[0],
    last_name: name_parts[1],
    mobile: random_mobile,
    email: random_email,
    source: %w[Website Facebook Instagram WhatsApp Referral Cold_Call].sample,
    stage: %w[New Contacted Qualified Proposal Negotiation Won Lost].sample,
    priority: %w[Low Medium High Urgent].sample,
    expected_policy_amount: [50000, 100000, 200000, 500000, 1000000].sample,
    assigned_to: agents.sample.id,
    status: true,
    address: random_address,
    city: CITIES.sample,
    state: STATES.sample,
    lead_source: %w[Online Referral Agent Social_Media].sample,
    call_disposition: %w[Interested Not_Interested Follow_Up Converted].sample,
    referral_amount: [1000, 2000, 5000, 10000].sample,
    transferred_amount: [true, false].sample,
    notes: "Lead generated from #{['website inquiry', 'referral', 'cold call', 'social media'].sample}",
    stage_updated_at: random_date_between(1.month.ago, Date.current)
  )

  # Convert some leads to customers
  if rand < 0.3 && customers.any?
    lead.update(
      converted_customer_id: customers.sample.id,
      stage: 'Won'
    )
  end
  lead
end
puts "   ✅ Created #{Lead.count} leads"

# 8. Create Health Insurance Policies (75 records)
puts "🏥 Creating Health Insurance Policies..."
health_insurances = 75.times.map do |i|
  customer = customers.sample
  lead = leads.sample
  company = insurance_companies.sample

  net_premium = [15000, 25000, 35000, 50000, 75000, 100000].sample
  gst = net_premium * 0.18

  HealthInsurance.create!(
    customer: customer,
    policy_holder: customer.display_name,
    plan_name: "#{['Arogya', 'Health', 'Care', 'Plus', 'Prime', 'Star'].sample} #{['Basic', 'Premium', 'Gold', 'Platinum'].sample}",
    insurance_company_name: company.name,
    insurance_type: %w[Individual Family Floater Senior_Citizen].sample,
    policy_type: %w[New Renewal Port].sample,
    policy_number: "HLT#{Time.current.year}#{sprintf('%08d', i+1)}",
    policy_booking_date: random_date_between(1.year.ago, Date.current),
    policy_start_date: random_date_between(Date.current, 1.month.from_now),
    policy_end_date: random_date_between(1.year.from_now, 2.years.from_now),
    payment_mode: %w[Yearly Half_Yearly Quarterly Monthly].sample,
    sum_insured: [300000, 500000, 1000000, 1500000, 2000000].sample,
    net_premium: net_premium,
    total_premium: net_premium + gst,
    gst_percentage: 18,
    lead_id: lead.lead_id,
    sub_agent_id: sub_agents.sample.id,
    distributor_id: distributors.sample.id,
    investor_id: investors.sample.id,
    main_agent_commission_received: [true, false].sample,
    agent_commission_amount: net_premium * 0.15,
    agent_commission_percentage: 15,
    added_by: %w[customer_request agent_recommendation system_migration].sample,
    is_customer_added: [true, false].sample,
    is_agent_added: [true, false].sample,
    is_admin_added: [true, false].sample
  )
end
puts "   ✅ Created #{HealthInsurance.count} health insurance policies"

# 9. Create Life Insurance Policies (60 records)
puts "❤️ Creating Life Insurance Policies..."
life_insurances = 60.times.map do |i|
  customer = customers.sample
  lead = leads.sample
  company = insurance_companies.sample

  net_premium = [25000, 50000, 75000, 100000, 150000, 200000].sample
  gst = net_premium * 0.18

  life_insurance = LifeInsurance.create!(
    customer: customer,
    policy_holder: customer.display_name,
    plan_name: "#{['Term', 'Endowment', 'ULIP', 'Whole', 'Money Back'].sample} #{['Life', 'Plus', 'Prime', 'Secure'].sample}",
    insurance_company_name: company.name,
    policy_type: %w[Term Endowment ULIP Whole_Life Money_Back].sample,
    policy_number: "LIFE#{Time.current.year}#{sprintf('%08d', i+1)}",
    policy_booking_date: random_date_between(1.year.ago, Date.current),
    policy_start_date: random_date_between(Date.current, 1.month.from_now),
    policy_end_date: random_date_between(5.years.from_now, 30.years.from_now),
    payment_mode: %w[Yearly Half_Yearly Quarterly Monthly].sample,
    sum_insured: [1000000, 2000000, 5000000, 10000000, 15000000].sample,
    net_premium: net_premium,
    total_premium: net_premium + gst,
    gst_percentage: 18,
    policy_term: [10, 15, 20, 25, 30].sample,
    premium_payment_term: [5, 10, 15, 20].sample,
    maturity_amount: [500000, 1000000, 2000000, 5000000].sample,
    lead_id: lead.lead_id,
    sub_agent_id: sub_agents.sample.id,
    distributor_id: distributors.sample.id,
    investor_id: investors.sample.id,
    main_agent_commission_received: [true, false].sample,
    agent_commission_amount: net_premium * 0.20,
    agent_commission_percentage: 20,
    added_by: %w[customer_request agent_recommendation system_migration].sample,
    is_customer_added: [true, false].sample,
    is_agent_added: [true, false].sample,
    is_admin_added: [true, false].sample
  )

  # Create nominees for life insurance
  rand(1..3).times do
    LifeInsuranceNominee.create!(
      life_insurance: life_insurance,
      nominee_name: random_name,
      nominee_relationship: %w[Spouse Child Parent Sibling].sample,
      nominee_percentage: [25, 50, 75, 100].sample,
      nominee_age: rand(1..80)
    )
  end

  life_insurance
end
puts "   ✅ Created #{LifeInsurance.count} life insurance policies with nominees"

# 10. Create Motor Insurance Policies (80 records)
puts "🚗 Creating Motor Insurance Policies..."
motor_insurances = 80.times.map do |i|
  customer = customers.sample
  lead = leads.sample
  company = insurance_companies.sample

  net_premium = [8000, 12000, 18000, 25000, 35000, 50000].sample
  gst = net_premium * 0.18

  vehicle_type = %w[Car Bike Truck Bus].sample
  make = vehicle_type == 'Bike' ? BIKE_MAKES.sample : CAR_MAKES.sample

  MotorInsurance.create!(
    customer: customer,
    policy_holder: customer.display_name,
    vehicle_type: vehicle_type,
    vehicle_make: make,
    vehicle_model: "#{make} #{['City', 'Swift', 'Verna', 'i20', 'Jazz', 'Baleno'].sample}",
    vehicle_variant: "#{['LX', 'VX', 'ZX', 'Base', 'Mid', 'Top'].sample} #{['Petrol', 'Diesel', 'CNG'].sample}",
    registration_number: "#{['KA', 'MH', 'DL', 'TN', 'AP'].sample}#{sprintf('%02d', rand(10..99))}#{('A'..'Z').to_a.sample}#{sprintf('%04d', rand(1000..9999))}",
    engine_number: "ENG#{rand(100000000000..999999999999)}",
    chassis_number: "CHA#{rand(100000000000000..999999999999999)}",
    manufacturing_year: rand(2015..2023),
    policy_number: "MTR#{Time.current.year}#{sprintf('%08d', i+1)}",
    insurance_company_name: company.name,
    policy_start_date: random_date_between(Date.current, 1.month.from_now),
    policy_end_date: random_date_between(11.months.from_now, 13.months.from_now),
    idv_amount: [300000, 500000, 800000, 1200000, 1500000].sample,
    net_premium: net_premium,
    total_premium: net_premium + gst,
    gst_percentage: 18,
    policy_type: %w[Comprehensive Third_Party].sample,
    coverage_type: %w[Own_Damage Third_Party Comprehensive].sample,
    lead_id: lead.lead_id,
    sub_agent_id: sub_agents.sample.id,
    distributor_id: distributors.sample.id,
    investor_id: investors.sample.id,
    main_agent_commission_received: [true, false].sample,
    agent_commission_amount: net_premium * 0.10,
    agent_commission_percentage: 10,
    added_by: %w[customer_request agent_recommendation system_migration].sample,
    is_customer_added: [true, false].sample,
    is_agent_added: [true, false].sample,
    is_admin_added: [true, false].sample,
    sum_insured: [300000, 500000, 800000, 1200000, 1500000].sample,
    status: %w[active expired cancelled].sample
  )
end
puts "   ✅ Created #{MotorInsurance.count} motor insurance policies"

# 11. Create Other Insurance Policies (40 records)
puts "🛡️ Creating Other Insurance Policies..."
other_insurances = 40.times.map do |i|
  customer = customers.sample
  lead = leads.sample
  company = insurance_companies.sample

  net_premium = [5000, 8000, 12000, 20000, 30000].sample
  gst = net_premium * 0.18

  OtherInsurance.create!(
    customer: customer,
    policy_holder: customer.display_name,
    insurance_type: ['Travel', 'Home', 'Personal Accident', 'Fire', 'Marine', 'Cyber'].sample,
    plan_name: "#{['Basic', 'Standard', 'Premium', 'Elite'].sample} #{['Protection', 'Cover', 'Shield', 'Guard'].sample}",
    insurance_company_name: company.name,
    policy_number: "OTH#{Time.current.year}#{sprintf('%08d', i+1)}",
    policy_start_date: random_date_between(Date.current, 1.month.from_now),
    policy_end_date: random_date_between(11.months.from_now, 13.months.from_now),
    policy_booking_date: random_date_between(1.month.ago, Date.current),
    sum_insured: [100000, 200000, 500000, 1000000].sample,
    net_premium: net_premium,
    total_premium: net_premium + gst,
    gst_percentage: 18,
    coverage_details: "Comprehensive coverage for #{['travel', 'home', 'personal accidents'].sample}",
    lead_id: lead.lead_id,
    sub_agent_id: sub_agents.sample.id,
    distributor_id: distributors.sample.id,
    investor_id: investors.sample.id,
    main_agent_commission_received: [true, false].sample,
    added_by: %w[customer_request agent_recommendation system_migration].sample,
    is_customer_added: [true, false].sample,
    is_agent_added: [true, false].sample,
    is_admin_added: [true, false].sample
  )
end
puts "   ✅ Created #{OtherInsurance.count} other insurance policies"

# 12. Create Investments (60 records)
puts "📈 Creating Investments..."
investments = 60.times.map do |i|
  Investment.create!(
    customer: customers.sample,
    investment_type: ['Mutual Fund', 'ELSS', 'SIP', 'Fixed Deposit', 'Bonds', 'Stocks'].sample,
    scheme_name: "#{['Growth', 'Dividend', 'Balanced', 'Equity', 'Debt'].sample} #{['Fund', 'Plan', 'Scheme'].sample}",
    amount_invested: [10000, 25000, 50000, 100000, 200000].sample,
    investment_date: random_date_between(2.years.ago, Date.current),
    maturity_date: random_date_between(1.year.from_now, 5.years.from_now),
    expected_returns: [8.5, 10.0, 12.0, 15.0, 18.0].sample,
    risk_level: ['Low', 'Medium', 'High'].sample,
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Active', 'Matured', 'Redeemed'].sample
  )
end
puts "   ✅ Created #{Investment.count} investments"

# 13. Create Loans (40 records)
puts "🏦 Creating Loans..."
loans = 40.times.map do |i|
  Loan.create!(
    customer: customers.sample,
    loan_type: ['Home Loan', 'Personal Loan', 'Car Loan', 'Business Loan', 'Education Loan'].sample,
    loan_amount: [500000, 1000000, 2000000, 5000000, 10000000].sample,
    interest_rate: [7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 12.0].sample,
    tenure_months: [12, 24, 60, 120, 180, 240, 360].sample,
    emi_amount: [5000, 10000, 15000, 25000, 50000].sample,
    loan_start_date: random_date_between(2.years.ago, Date.current),
    loan_end_date: random_date_between(1.year.from_now, 30.years.from_now),
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Active', 'Closed', 'Defaulted'].sample
  )
end
puts "   ✅ Created #{Loan.count} loans"

# 14. Create Tax Services (30 records)
puts "📊 Creating Tax Services..."
tax_services = 30.times.map do |i|
  TaxService.create!(
    customer: customers.sample,
    service_type: ['ITR Filing', 'GST Registration', 'GST Filing', 'TDS Return', 'Audit Services'].sample,
    financial_year: ["#{2020 + rand(4)}-#{2021 + rand(4)}"].sample,
    service_date: random_date_between(1.year.ago, Date.current),
    service_amount: [1000, 2000, 5000, 10000, 25000].sample,
    completion_date: random_date_between(Date.current, 3.months.from_now),
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Pending', 'In Progress', 'Completed'].sample
  )
end
puts "   ✅ Created #{TaxService.count} tax services"

# 15. Create Travel Packages (50 records)
puts "✈️ Creating Travel Packages..."
travel_packages = 50.times.map do |i|
  TravelPackage.create!(
    customer: customers.sample,
    package_name: "#{['Goa', 'Kerala', 'Rajasthan', 'Himachal', 'Kashmir', 'Europe', 'Thailand', 'Dubai'].sample} #{['Delight', 'Explorer', 'Adventure', 'Romantic', 'Family'].sample}",
    destination: ['Goa', 'Kerala', 'Rajasthan', 'Himachal Pradesh', 'Kashmir', 'Europe', 'Thailand', 'Dubai', 'Singapore', 'Bali'].sample,
    travel_date: random_date_between(Date.current, 1.year.from_now),
    return_date: random_date_between(1.week.from_now, 1.year.from_now),
    number_of_travelers: rand(1..8),
    package_amount: [25000, 50000, 75000, 100000, 150000, 200000].sample,
    booking_date: random_date_between(1.month.ago, Date.current),
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Booked', 'Confirmed', 'Cancelled', 'Completed'].sample
  )
end
puts "   ✅ Created #{TravelPackage.count} travel packages"

# 16. Create Commission Payouts (60 records)
puts "💰 Creating Commission Payouts..."
all_policies = health_insurances + life_insurances + motor_insurances + other_insurances

commission_payouts = 60.times.map do |i|
  policy = all_policies.sample
  policy_type = case policy.class.name
                when 'HealthInsurance' then 'health'
                when 'LifeInsurance' then 'life'
                when 'MotorInsurance' then 'motor'
                when 'OtherInsurance' then 'other'
                end

  payout_amount = policy.net_premium * [0.05, 0.10, 0.15, 0.20].sample

  CommissionPayout.create!(
    policy_type: policy_type,
    policy_id: policy.id,
    payout_to: ['affiliate', 'distributor', 'investor', 'company'].sample,
    payout_amount: payout_amount,
    payout_date: random_date_between(1.month.ago, Date.current),
    status: ['pending', 'paid', 'cancelled'].sample,
    transaction_id: "TXN#{Time.current.year}#{sprintf('%08d', i+1)}",
    payment_mode: ['bank_transfer', 'cheque', 'cash', 'online'].sample,
    reference_number: "REF#{sprintf('%08d', i+1)}",
    notes: "Commission payout for #{policy_type} policy",
    processed_by: agents.sample.email,
    processed_at: random_date_between(1.week.ago, Date.current).to_time
  )
end
puts "   ✅ Created #{CommissionPayout.count} commission payouts"

# 17. Create Distributor Payouts (30 records)
puts "🏢 Creating Distributor Payouts..."
distributor_payouts = 30.times.map do |i|
  policy = all_policies.sample
  distributor = distributors.sample
  policy_type = case policy.class.name
                when 'HealthInsurance' then 'health'
                when 'LifeInsurance' then 'life'
                when 'MotorInsurance' then 'motor'
                when 'OtherInsurance' then 'other'
                end

  payout_amount = policy.net_premium * 0.03 # 3% for distributors

  DistributorPayout.create!(
    distributor: distributor,
    policy_type: policy_type,
    policy_id: policy.id,
    payout_amount: payout_amount,
    payout_date: random_date_between(1.month.ago, Date.current),
    status: ['pending', 'paid', 'cancelled'].sample,
    transaction_id: "DIST#{Time.current.year}#{sprintf('%08d', i+1)}",
    payment_mode: ['bank_transfer', 'cheque', 'online'].sample,
    reference_number: "DISTREF#{sprintf('%08d', i+1)}",
    notes: "Distributor payout for #{policy_type} policy",
    processed_by: agents.sample.email,
    processed_at: random_date_between(1.week.ago, Date.current).to_time
  )
end
puts "   ✅ Created #{DistributorPayout.count} distributor payouts"

# 18. Create Family Members (120 records)
puts "👨‍👩‍👧‍👦 Creating Family Members..."
family_members = 120.times.map do |i|
  FamilyMember.create!(
    customer: customers.sample,
    first_name: FIRST_NAMES.sample,
    last_name: LAST_NAMES.sample,
    relationship: ['Spouse', 'Child', 'Parent', 'Sibling'].sample,
    birth_date: random_date_between(80.years.ago, Date.current),
    gender: ['Male', 'Female'].sample,
    mobile: rand(2) == 0 ? random_mobile : nil,
    aadhar_no: rand(2) == 0 ? rand(100000000000..999999999999).to_s : nil
  )
end
puts "   ✅ Created #{FamilyMember.count} family members"

# 19. Create Client Requests (50 records)
puts "📞 Creating Client Requests..."
client_requests = 50.times.map do |i|
  ClientRequest.create!(
    customer: customers.sample,
    request_type: ['Policy Update', 'Claim Assistance', 'Renewal Reminder', 'New Policy', 'Complaint', 'General Inquiry'].sample,
    subject: "Request for #{['policy information', 'claim processing', 'renewal assistance'].sample}",
    description: "Customer has requested assistance with #{['policy details', 'claim settlement', 'renewal process'].sample}. Please follow up promptly.",
    priority: ['Low', 'Medium', 'High', 'Urgent'].sample,
    status: ['Pending', 'In Progress', 'Resolved', 'Closed'].sample,
    assigned_to: agents.sample.id,
    resolved_at: rand(2) == 0 ? random_date_between(1.week.ago, Date.current).to_time : nil
  )
end
puts "   ✅ Created #{ClientRequest.count} client requests"

# Final Summary
puts "\n🎉 Test data generation completed successfully!"
puts "="*60

# Generate comprehensive summary
summary = {
  "👥 Users" => User.count,
  "👨‍👩‍👧‍👦 Customers" => Customer.count,
  "👨‍👩‍👧‍👦 Family Members" => FamilyMember.count,
  "🏢 Distributors" => Distributor.count,
  "🤝 Sub Agents" => SubAgent.count,
  "💼 Investors" => Investor.count,
  "🏛️ Insurance Companies" => InsuranceCompany.count,
  "🎯 Leads" => Lead.count,
  "🏥 Health Insurance" => HealthInsurance.count,
  "❤️ Life Insurance" => LifeInsurance.count,
  "🚗 Motor Insurance" => MotorInsurance.count,
  "🛡️ Other Insurance" => OtherInsurance.count,
  "📈 Investments" => Investment.count,
  "🏦 Loans" => Loan.count,
  "📊 Tax Services" => TaxService.count,
  "✈️ Travel Packages" => TravelPackage.count,
  "💰 Commission Payouts" => CommissionPayout.count,
  "🏢 Distributor Payouts" => DistributorPayout.count,
  "📞 Client Requests" => ClientRequest.count
}

summary.each do |model, count|
  puts "#{model}: #{count} records"
end

total_records = summary.values.sum
puts "="*60
puts "🚀 TOTAL RECORDS CREATED: #{total_records}"
puts "="*60

# Sample user credentials for testing
puts "\n🔑 Sample Login Credentials:"
puts "="*40
puts "Admin User:"
puts "Email: admin1@drwise.com"
puts "Password: password123"
puts ""
puts "Agent User:"
puts "Email: agent1@insurebook.com"
puts "Password: password123"
puts ""
puts "Customer User:"
puts "Email: customer1@insurebook.com"
puts "Password: password123"
puts "="*40

puts "\n✨ All models populated with realistic test data!"
puts "💡 You can now test all features with comprehensive data sets."
puts "\nNote: This script uses no external dependencies and generates Indian-specific test data."