# Comprehensive Test Data Generation Script
# Run this in Rails console with: load 'db/seeds_test_data.rb'

puts "🚀 Starting comprehensive test data generation..."

# Check for required gems
begin
  require 'faker'
rescue LoadError
  puts "❌ Faker gem not found. Installing..."
  system('bundle add faker')
  require 'faker'
end

# Ensure Faker is properly configured
Faker::Config.locale = 'en'

# Clear existing data (optional - uncomment if needed)
# puts "🧹 Clearing existing data..."
# [DistributorPayout, CommissionPayout, DistributorAssignment, Lead, MotorInsurance,
#  HealthInsurance, LifeInsurance, OtherInsurance, Investment, Loan, TaxService, TravelPackage,
#  SubAgent, Distributor, Investor, Customer, User].each(&:delete_all)

# Helper method to create users with proper attributes
def create_test_user(user_type, count = 1)
  count.times.map do
    User.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.unique.email,
      password: 'password123',
      mobile: Faker::PhoneNumber.unique.cell_phone_in_e164[0..10],
      user_type: user_type,
      role: case user_type
            when 'admin' then 'super_admin'
            when 'agent' then 'agent_role'
            else 'user_role'
            end,
      status: true
    )
  end
end

# 1. Create Users (100 total)
puts "👥 Creating Users..."
admins = create_test_user('admin', 10)
agents = create_test_user('agent', 40)
customers_users = create_test_user('customer', 50)
puts "   ✅ Created #{User.count} users"

# 2. Create Customers (150 records)
puts "👨‍👩‍👧‍👦 Creating Customers..."
customers = 150.times.map do
  Customer.create!(
    first_name: Faker::Name.first_name,
    middle_name: [Faker::Name.middle_name, nil].sample,
    last_name: Faker::Name.last_name,
    mobile: Faker::PhoneNumber.unique.cell_phone_in_e164[0..10],
    email: Faker::Internet.unique.email,
    pan_no: Faker::Alphanumeric.alpha(number: 5).upcase + Faker::Number.number(digits: 4).to_s + Faker::Alphanumeric.alpha(number: 1).upcase,
    aadhar_no: Faker::Number.unique.number(digits: 12).to_s,
    birth_date: Faker::Date.birthday(min_age: 18, max_age: 80),
    gender: %w[Male Female Other].sample,
    address: Faker::Address.full_address,
    city: Faker::Address.city,
    state: Faker::Address.state,
    pincode: Faker::Address.zip_code[0..5],
    marital_status: %w[Single Married Divorced Widowed].sample,
    occupation: Faker::Job.title,
    annual_income: [300000, 500000, 800000, 1200000, 1500000, 2000000].sample,
    nominee_name: Faker::Name.name,
    nominee_relationship: %w[Spouse Child Parent Sibling].sample,
    bank_name: Faker::Bank.name,
    account_no: Faker::Bank.account_number,
    ifsc_code: Faker::Bank.swift_bic,
    account_holder_name: Faker::Name.name,
    status: true
  )
end
puts "   ✅ Created #{Customer.count} customers"

# 3. Create Distributors (25 records)
puts "🏢 Creating Distributors..."
distributors = 25.times.map do
  Distributor.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    company_name: Faker::Company.name,
    mobile: Faker::PhoneNumber.unique.cell_phone_in_e164[0..10],
    email: Faker::Internet.unique.email,
    pan_no: Faker::Alphanumeric.alpha(number: 5).upcase + Faker::Number.number(digits: 4).to_s + Faker::Alphanumeric.alpha(number: 1).upcase,
    gst_no: Faker::Number.unique.number(digits: 15).to_s,
    address: Faker::Address.full_address,
    city: Faker::Address.city,
    state: Faker::Address.state,
    pincode: Faker::Address.zip_code[0..5],
    bank_name: Faker::Bank.name,
    account_no: Faker::Bank.account_number,
    ifsc_code: Faker::Bank.swift_bic,
    commission_percentage: [2.0, 2.5, 3.0, 3.5, 4.0].sample,
    status: true,
    affiliate_count: rand(5..15)
  )
end
puts "   ✅ Created #{Distributor.count} distributors"

# 4. Create Sub Agents (75 records)
puts "🤝 Creating Sub Agents..."
sub_agents = 75.times.map do
  SubAgent.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    mobile: Faker::PhoneNumber.unique.cell_phone_in_e164[0..10],
    email: Faker::Internet.unique.email,
    pan_no: Faker::Alphanumeric.alpha(number: 5).upcase + Faker::Number.number(digits: 4).to_s + Faker::Alphanumeric.alpha(number: 1).upcase,
    aadhar_no: Faker::Number.unique.number(digits: 12).to_s,
    birth_date: Faker::Date.birthday(min_age: 21, max_age: 65),
    gender: %w[Male Female].sample,
    address: Faker::Address.full_address,
    city: Faker::Address.city,
    state: Faker::Address.state,
    bank_name: Faker::Bank.name,
    account_no: Faker::Bank.account_number,
    ifsc_code: Faker::Bank.swift_bic,
    distributor: distributors.sample,
    status: true,
    password: 'password123'
  )
end
puts "   ✅ Created #{SubAgent.count} sub agents"

# 5. Create Investors (30 records)
puts "💼 Creating Investors..."
investors = 30.times.map do
  Investor.create!(
    first_name: Faker::Name.first_name,
    middle_name: [Faker::Name.middle_name, nil].sample,
    last_name: Faker::Name.last_name,
    mobile: Faker::PhoneNumber.unique.cell_phone_in_e164[0..10],
    email: Faker::Internet.unique.email,
    birth_date: Faker::Date.birthday(min_age: 25, max_age: 70),
    gender: %w[Male Female].sample,
    pan_no: Faker::Alphanumeric.alpha(number: 5).upcase + Faker::Number.number(digits: 4).to_s + Faker::Alphanumeric.alpha(number: 1).upcase,
    gst_no: [Faker::Number.unique.number(digits: 15).to_s, nil].sample,
    company_name: [Faker::Company.name, nil].sample,
    address: Faker::Address.full_address,
    bank_name: Faker::Bank.name,
    account_no: Faker::Bank.account_number,
    ifsc_code: Faker::Bank.swift_bic,
    account_holder_name: Faker::Name.name,
    account_type: %w[Savings Current].sample,
    upi_id: "#{Faker::Internet.username}@#{['paytm', 'phonepe', 'gpay'].sample}",
    status: 1
  )
end
puts "   ✅ Created #{Investor.count} investors"

# 6. Create Insurance Companies (15 records)
puts "🏛️ Creating Insurance Companies..."
insurance_companies = [
  'ICICI Lombard', 'HDFC ERGO', 'Bajaj Allianz', 'IFFCO Tokio', 'Reliance General',
  'SBI General', 'New India Assurance', 'Oriental Insurance', 'United India Insurance',
  'National Insurance', 'Cholamandalam MS', 'Future Generali', 'Liberty General',
  'Shriram Insurance', 'Digit Insurance'
].map do |name|
  InsuranceCompany.create!(
    name: name,
    address: Faker::Address.full_address,
    contact_number: Faker::PhoneNumber.phone_number,
    email: Faker::Internet.email(domain: name.downcase.gsub(/\s+/, '') + '.com'),
    website: "www.#{name.downcase.gsub(/\s+/, '')}.com",
    license_number: "LIC#{Faker::Number.unique.number(digits: 8)}",
    status: true
  )
end
puts "   ✅ Created #{InsuranceCompany.count} insurance companies"

# 7. Create Leads (200 records)
puts "🎯 Creating Leads..."
leads = 200.times.map do
  lead = Lead.create!(
    lead_id: "LEAD#{Time.current.year}#{Faker::Number.unique.number(digits: 6)}",
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    mobile: Faker::PhoneNumber.unique.cell_phone_in_e164[0..10],
    email: Faker::Internet.unique.email,
    source: %w[Website Facebook Instagram WhatsApp Referral Cold_Call].sample,
    stage: %w[New Contacted Qualified Proposal Negotiation Won Lost].sample,
    priority: %w[Low Medium High Urgent].sample,
    expected_policy_amount: [50000, 100000, 200000, 500000, 1000000].sample,
    notes: Faker::Lorem.paragraph(sentence_count: 2),
    assigned_to: agents.sample.id,
    status: true,
    address: Faker::Address.full_address,
    city: Faker::Address.city,
    state: Faker::Address.state,
    lead_source: %w[Online Referral Agent Social_Media].sample,
    call_disposition: %w[Interested Not_Interested Follow_Up Converted].sample,
    referral_amount: [1000, 2000, 5000, 10000].sample,
    transferred_amount: [true, false].sample,
    notes: Faker::Lorem.paragraph,
    stage_updated_at: Faker::Time.between(from: 1.month.ago, to: Time.current)
  )

  # Sometimes convert leads to customers
  if rand < 0.3 && customers.any?
    lead.update(
      converted_customer_id: customers.sample.id,
      stage: 'Won'
    )
  end
  lead
end
puts "   ✅ Created #{Lead.count} leads"

# 8. Create Health Insurance Policies (100 records)
puts "🏥 Creating Health Insurance Policies..."
health_insurances = 100.times.map do
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
    policy_number: "HLT#{Faker::Number.unique.number(digits: 10)}",
    policy_booking_date: Faker::Date.between(from: 1.year.ago, to: Date.current),
    policy_start_date: Faker::Date.between(from: Date.current, to: 1.month.from_now),
    policy_end_date: Faker::Date.between(from: 1.year.from_now, to: 2.years.from_now),
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

# 9. Create Life Insurance Policies (80 records)
puts "❤️ Creating Life Insurance Policies..."
life_insurances = 80.times.map do
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
    policy_number: "LIFE#{Faker::Number.unique.number(digits: 10)}",
    policy_booking_date: Faker::Date.between(from: 1.year.ago, to: Date.current),
    policy_start_date: Faker::Date.between(from: Date.current, to: 1.month.from_now),
    policy_end_date: Faker::Date.between(from: 5.years.from_now, to: 30.years.from_now),
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
      nominee_name: Faker::Name.name,
      nominee_relationship: %w[Spouse Child Parent Sibling].sample,
      nominee_percentage: [25, 50, 75, 100].sample,
      nominee_age: rand(1..80)
    )
  end

  life_insurance
end
puts "   ✅ Created #{LifeInsurance.count} life insurance policies with nominees"

# 10. Create Motor Insurance Policies (120 records)
puts "🚗 Creating Motor Insurance Policies..."
motor_insurances = 120.times.map do
  customer = customers.sample
  lead = leads.sample
  company = insurance_companies.sample

  net_premium = [8000, 12000, 18000, 25000, 35000, 50000].sample
  gst = net_premium * 0.18

  MotorInsurance.create!(
    customer: customer,
    policy_holder: customer.display_name,
    vehicle_type: %w[Car Bike Truck Bus].sample,
    vehicle_make: ['Maruti', 'Hyundai', 'Honda', 'Toyota', 'Tata', 'Mahindra', 'Bajaj', 'Hero'].sample,
    vehicle_model: Faker::Vehicle.model,
    vehicle_variant: "#{['LX', 'VX', 'ZX', 'Base', 'Mid', 'Top'].sample} #{['Petrol', 'Diesel', 'CNG'].sample}",
    registration_number: "#{['KA', 'MH', 'DL', 'TN', 'AP'].sample}#{rand(10..99)}#{('A'..'Z').to_a.sample}#{rand(1000..9999)}",
    engine_number: Faker::Vehicle.vin[0..10],
    chassis_number: Faker::Vehicle.vin,
    manufacturing_year: rand(2015..2023),
    policy_number: "MTR#{Faker::Number.unique.number(digits: 10)}",
    insurance_company_name: company.name,
    policy_start_date: Faker::Date.between(from: Date.current, to: 1.month.from_now),
    policy_end_date: Faker::Date.between(from: 11.months.from_now, to: 13.months.from_now),
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

# 11. Create Other Insurance Policies (60 records)
puts "🛡️ Creating Other Insurance Policies..."
other_insurances = 60.times.map do
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
    policy_number: "OTH#{Faker::Number.unique.number(digits: 10)}",
    policy_start_date: Faker::Date.between(from: Date.current, to: 1.month.from_now),
    policy_end_date: Faker::Date.between(from: 11.months.from_now, to: 13.months.from_now),
    policy_booking_date: Faker::Date.between(from: 1.month.ago, to: Date.current),
    sum_insured: [100000, 200000, 500000, 1000000].sample,
    net_premium: net_premium,
    total_premium: net_premium + gst,
    gst_percentage: 18,
    coverage_details: Faker::Lorem.paragraph,
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

# 12. Create Investments (80 records)
puts "📈 Creating Investments..."
investments = 80.times.map do
  Investment.create!(
    customer: customers.sample,
    investment_type: ['Mutual Fund', 'ELSS', 'SIP', 'Fixed Deposit', 'Bonds', 'Stocks'].sample,
    scheme_name: "#{['Growth', 'Dividend', 'Balanced', 'Equity', 'Debt'].sample} #{['Fund', 'Plan', 'Scheme'].sample}",
    amount_invested: [10000, 25000, 50000, 100000, 200000].sample,
    investment_date: Faker::Date.between(from: 2.years.ago, to: Date.current),
    maturity_date: Faker::Date.between(from: 1.year.from_now, to: 5.years.from_now),
    expected_returns: [8.5, 10.0, 12.0, 15.0, 18.0].sample,
    risk_level: ['Low', 'Medium', 'High'].sample,
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Active', 'Matured', 'Redeemed'].sample
  )
end
puts "   ✅ Created #{Investment.count} investments"

# 13. Create Loans (60 records)
puts "🏦 Creating Loans..."
loans = 60.times.map do
  Loan.create!(
    customer: customers.sample,
    loan_type: ['Home Loan', 'Personal Loan', 'Car Loan', 'Business Loan', 'Education Loan'].sample,
    loan_amount: [500000, 1000000, 2000000, 5000000, 10000000].sample,
    interest_rate: [7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 12.0].sample,
    tenure_months: [12, 24, 60, 120, 180, 240, 360].sample,
    emi_amount: [5000, 10000, 15000, 25000, 50000].sample,
    loan_start_date: Faker::Date.between(from: 2.years.ago, to: Date.current),
    loan_end_date: Faker::Date.between(from: 1.year.from_now, to: 30.years.from_now),
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Active', 'Closed', 'Defaulted'].sample
  )
end
puts "   ✅ Created #{Loan.count} loans"

# 14. Create Tax Services (40 records)
puts "📊 Creating Tax Services..."
tax_services = 40.times.map do
  TaxService.create!(
    customer: customers.sample,
    service_type: ['ITR Filing', 'GST Registration', 'GST Filing', 'TDS Return', 'Audit Services'].sample,
    financial_year: ["#{2020 + rand(4)}-#{2021 + rand(4)}"].sample,
    service_date: Faker::Date.between(from: 1.year.ago, to: Date.current),
    service_amount: [1000, 2000, 5000, 10000, 25000].sample,
    completion_date: Faker::Date.between(from: Date.current, to: 3.months.from_now),
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Pending', 'In Progress', 'Completed'].sample
  )
end
puts "   ✅ Created #{TaxService.count} tax services"

# 15. Create Travel Packages (70 records)
puts "✈️ Creating Travel Packages..."
travel_packages = 70.times.map do
  TravelPackage.create!(
    customer: customers.sample,
    package_name: "#{['Goa', 'Kerala', 'Rajasthan', 'Himachal', 'Kashmir', 'Europe', 'Thailand', 'Dubai'].sample} #{['Delight', 'Explorer', 'Adventure', 'Romantic', 'Family'].sample}",
    destination: ['Goa', 'Kerala', 'Rajasthan', 'Himachal Pradesh', 'Kashmir', 'Europe', 'Thailand', 'Dubai', 'Singapore', 'Bali'].sample,
    travel_date: Faker::Date.between(from: Date.current, to: 1.year.from_now),
    return_date: Faker::Date.between(from: 1.week.from_now, to: 1.year.from_now),
    number_of_travelers: rand(1..8),
    package_amount: [25000, 50000, 75000, 100000, 150000, 200000].sample,
    booking_date: Faker::Date.between(from: 1.month.ago, to: Date.current),
    distributor: distributors.sample,
    sub_agent: sub_agents.sample,
    status: ['Booked', 'Confirmed', 'Cancelled', 'Completed'].sample
  )
end
puts "   ✅ Created #{TravelPackage.count} travel packages"

# 16. Create Commission Payouts (100 records)
puts "💰 Creating Commission Payouts..."
all_policies = health_insurances + life_insurances + motor_insurances + other_insurances

commission_payouts = 100.times.map do
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
    payout_date: Faker::Date.between(from: 1.month.ago, to: Date.current),
    status: ['pending', 'paid', 'cancelled'].sample,
    transaction_id: "TXN#{Faker::Number.unique.number(digits: 10)}",
    payment_mode: ['bank_transfer', 'cheque', 'cash', 'online'].sample,
    reference_number: "REF#{Faker::Number.number(digits: 8)}",
    notes: Faker::Lorem.sentence,
    processed_by: agents.sample.email,
    processed_at: Faker::Time.between(from: 1.week.ago, to: Time.current)
  )
end
puts "   ✅ Created #{CommissionPayout.count} commission payouts"

# 17. Create Distributor Payouts (50 records)
puts "🏢 Creating Distributor Payouts..."
distributor_payouts = 50.times.map do
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
    payout_date: Faker::Date.between(from: 1.month.ago, to: Date.current),
    status: ['pending', 'paid', 'cancelled'].sample,
    transaction_id: "DIST#{Faker::Number.unique.number(digits: 10)}",
    payment_mode: ['bank_transfer', 'cheque', 'online'].sample,
    reference_number: "DISTREF#{Faker::Number.number(digits: 8)}",
    notes: "Distributor payout for #{policy_type} policy",
    processed_by: agents.sample.email,
    processed_at: Faker::Time.between(from: 1.week.ago, to: Time.current)
  )
end
puts "   ✅ Created #{DistributorPayout.count} distributor payouts"

# 18. Create Family Members (200 records)
puts "👨‍👩‍👧‍👦 Creating Family Members..."
family_members = 200.times.map do
  FamilyMember.create!(
    customer: customers.sample,
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    relationship: ['Spouse', 'Child', 'Parent', 'Sibling'].sample,
    birth_date: Faker::Date.birthday(min_age: 0, max_age: 80),
    gender: ['Male', 'Female'].sample,
    mobile: [Faker::PhoneNumber.cell_phone_in_e164[0..10], nil].sample,
    aadhar_no: [Faker::Number.unique.number(digits: 12).to_s, nil].sample
  )
end
puts "   ✅ Created #{FamilyMember.count} family members"

# 19. Create Client Requests (80 records)
puts "📞 Creating Client Requests..."
client_requests = 80.times.map do
  ClientRequest.create!(
    customer: customers.sample,
    request_type: ['Policy Update', 'Claim Assistance', 'Renewal Reminder', 'New Policy', 'Complaint', 'General Inquiry'].sample,
    subject: Faker::Lorem.sentence,
    description: Faker::Lorem.paragraph(sentence_count: 3),
    priority: ['Low', 'Medium', 'High', 'Urgent'].sample,
    status: ['Pending', 'In Progress', 'Resolved', 'Closed'].sample,
    assigned_to: agents.sample.id,
    resolved_at: [Faker::Time.between(from: 1.week.ago, to: Time.current), nil].sample
  )
end
puts "   ✅ Created #{ClientRequest.count} client requests"

# 20. Create Banners (15 records)
puts "🎨 Creating Banners..."
banners = 15.times.map do
  Banner.create!(
    title: Faker::Marketing.buzzwords.titleize,
    description: Faker::Lorem.paragraph,
    redirect_link: Faker::Internet.url,
    display_start_date: Faker::Date.between(from: 1.month.ago, to: Date.current),
    display_end_date: Faker::Date.between(from: Date.current, to: 3.months.from_now),
    display_location: ['Home Page', 'Dashboard', 'Policy List', 'Customer Portal'].sample,
    status: [true, false].sample,
    display_order: rand(1..10)
  )
end
puts "   ✅ Created #{Banner.count} banners"

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
  "📞 Client Requests" => ClientRequest.count,
  "🎨 Banners" => Banner.count
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
puts "Email: #{User.where(user_type: 'admin').first&.email}"
puts "Password: password123"
puts ""
puts "Agent User:"
puts "Email: #{User.where(user_type: 'agent').first&.email}"
puts "Password: password123"
puts ""
puts "Customer User:"
puts "Email: #{User.where(user_type: 'customer').first&.email}"
puts "Password: password123"
puts "="*40

puts "\n✨ All models populated with realistic test data!"
puts "💡 You can now test all features with comprehensive data sets."