# Comprehensive Mobile API Seed Data Script
# This script creates complete test data for all mobile APIs including upcoming installments

puts "🚀 Starting comprehensive mobile API seed data creation..."

# Clear existing data (optional - uncomment if needed)
# puts "🧹 Clearing existing data..."
# HealthInsuranceMember.destroy_all
# HealthInsurance.destroy_all
# LifeInsurance.destroy_all
# FamilyMember.destroy_all
# Customer.destroy_all
# SubAgent.destroy_all
# Broker.destroy_all
# AgencyCode.destroy_all

# Create Sub Agents
puts "👥 Creating Sub Agents..."
sub_agents = []

5.times do |i|
  sub_agent = SubAgent.create!(
    first_name: "Agent#{i + 1}",
    last_name: "Kumar",
    mobile: "987654#{1000 + i}",
    email: "agent#{i + 1}@insurebook.com",
    role_id: 1, # Assuming role_id 1 exists
    birth_date: 30.years.ago + rand(10.years),
    gender: ['Male', 'Female'].sample,
    pan_no: "ABCDE#{1000 + i}F",
    company_name: "InsureBook Agent #{i + 1}",
    address: "#{100 + i} Agent Street, Mumbai, Maharashtra",
    bank_name: "HDFC Bank",
    account_no: "123456#{1000 + i}",
    ifsc_code: "HDFC0000#{100 + i}",
    account_holder_name: "Agent#{i + 1} Kumar",
    account_type: "Savings",
    upi_id: "agent#{i + 1}@paytm",
    status: 'active'
  )
  sub_agents << sub_agent
end

# Create Brokers
puts "🏢 Creating Brokers..."
brokers = []

3.times do |i|
  broker = Broker.create!(
    name: "Broker Company #{i + 1}",
    status: 'active'
  )
  brokers << broker
end

# Create Agency Codes
puts "🏷️  Creating Agency Codes..."
agency_codes = []

['Health', 'Life', 'Motor'].each_with_index do |type, i|
  agency_code = AgencyCode.create!(
    insurance_type: type,
    company_name: "LIC of India",
    agent_name: "Main Agent",
    code: "AG#{type.upcase}#{1000 + i}"
  )
  agency_codes << agency_code
end

# Create Customers with comprehensive data
puts "👨‍👩‍👧‍👦 Creating Customers with family members..."
customers = []

10.times do |i|
  # Create customer
  customer = Customer.create!(
    customer_type: ['individual', 'corporate'].sample,
    first_name: "Customer#{i + 1}",
    middle_name: "Middle",
    last_name: "Kumar",
    email: "customer#{i + 1}@example.com",
    mobile: "987654#{5000 + i}",
    address: "#{100 + i} Customer Street, Mumbai, Maharashtra",
    state: "Maharashtra",
    city: "Mumbai",
    pincode: "400001",
    birth_date: 35.years.ago + rand(20.years),
    age: 35 + rand(20),
    gender: ['Male', 'Female'].sample,
    height: "5.8",
    height_feet: "5'8\"",
    weight: "70",
    weight_kg: 70.5,
    education: ['Graduate', 'Post Graduate', 'Professional'].sample,
    marital_status: ['Single', 'Married'].sample,
    occupation: ['Business', 'Service', 'Professional'].sample,
    business_job: "Software Engineer",
    business_name: "Tech Corp",
    annual_income: 500000 + rand(1500000),
    pan_number: "ABCDE#{2000 + i}F",
    pan_no: "ABCDE#{2000 + i}F",
    gst_number: "27ABCDE#{2000 + i}F1Z5",
    gst_no: "27ABCDE#{2000 + i}F1Z5",
    birth_place: "Mumbai",
    nominee_name: "Nominee #{i + 1}",
    nominee_relation: "Spouse",
    nominee_date_of_birth: 30.years.ago + rand(10.years),
    status: true,
    added_by: "admin",
    sub_agent: sub_agents.sample.display_name,
    additional_info: "Customer created for mobile API testing",
    additional_information: "Additional details for customer #{i + 1}"
  )

  # Create family members for each customer
  family_relationships = ['Spouse', 'Son', 'Daughter', 'Father', 'Mother']

  rand(2..4).times do |j|
    FamilyMember.create!(
      customer: customer,
      first_name: "Family#{j + 1}",
      middle_name: "Mid",
      last_name: "Kumar",
      birth_date: 25.years.ago + rand(30.years),
      age: 25 + rand(30),
      height: "5.6",
      height_feet: "5'6\"",
      weight: "65",
      weight_kg: 65.5,
      gender: ['Male', 'Female'].sample,
      relationship: family_relationships[j % family_relationships.length],
      pan_no: "FMLY#{i}#{j}#{1000}F",
      mobile: "876543#{2000 + (i * 10) + j}",
      additional_information: "Family member #{j + 1} of customer #{i + 1}"
    )
  end

  customers << customer
end

# Create Health Insurance Policies with complete data
puts "🏥 Creating Health Insurance Policies..."
health_insurances = []

customers.each_with_index do |customer, i|
  # Create 1-3 health insurance policies per customer
  rand(1..3).times do |j|
    policy_start_date = rand(2.years.ago..1.year.from_now)
    policy_end_date = policy_start_date + 1.year

    # Set autopay dates for upcoming installments
    autopay_start_date = policy_start_date + rand(1..11).months
    autopay_end_date = policy_end_date

    net_premium = [25000, 35000, 50000, 75000, 100000].sample
    gst_percentage = 18
    total_premium = net_premium + (net_premium * gst_percentage / 100)
    commission_percentage = rand(15..25)
    commission_amount = net_premium * commission_percentage / 100

    health_insurance = HealthInsurance.create!(
      customer: customer,
      sub_agent: sub_agents.sample,
      agency_code: agency_codes.find_by(insurance_type: 'Health'),
      broker: brokers.sample,
      policy_holder: customer.display_name,
      insurance_company_name: ['Star Health Insurance', 'HDFC ERGO Health Insurance', 'Care Health Insurance', 'Niva Bupa Health Insurance'].sample,
      plan_name: "Family Health Plan #{j + 1}",
      policy_number: "HLT#{Time.current.year}#{i.to_s.rjust(3, '0')}#{j.to_s.rjust(2, '0')}",
      insurance_type: ['Individual', 'Family Floater'].sample,
      policy_type: ['New', 'Renewal'].sample,
      policy_booking_date: policy_start_date - rand(1..30).days,
      policy_start_date: policy_start_date,
      policy_end_date: policy_end_date,
      policy_term: 1,
      payment_mode: ['Monthly', 'Quarterly', 'Half Yearly', 'Yearly'].sample,
      sum_insured: [300000, 500000, 750000, 1000000].sample,
      net_premium: net_premium,
      gst_percentage: gst_percentage,
      total_premium: total_premium,
      main_agent_commission_percentage: commission_percentage,
      commission_amount: commission_amount,
      tds_percentage: 10,
      tds_amount: commission_amount * 0.1,
      after_tds_value: commission_amount * 0.9,
      installment_autopay_start_date: autopay_start_date,
      installment_autopay_end_date: autopay_end_date,
      claim_process: "Cashless and Reimbursement"
    )

    # Create health insurance members
    if health_insurance.insurance_type == 'Family Floater'
      # Add customer as primary member
      HealthInsuranceMember.create!(
        health_insurance: health_insurance,
        member_name: customer.display_name,
        age: customer.age,
        relationship: 'Self',
        sum_insured: health_insurance.sum_insured
      )

      # Add family members
      customer.family_members.limit(3).each do |family_member|
        HealthInsuranceMember.create!(
          health_insurance: health_insurance,
          member_name: family_member.full_name,
          age: family_member.age,
          relationship: family_member.relationship,
          sum_insured: health_insurance.sum_insured
        )
      end
    end

    health_insurances << health_insurance
  end
end

# Create Life Insurance Policies with complete data
puts "👨‍👩‍👧‍👦 Creating Life Insurance Policies..."
life_insurances = []

customers.each_with_index do |customer, i|
  # Create 1-2 life insurance policies per customer
  rand(1..2).times do |j|
    policy_start_date = rand(3.years.ago..6.months.from_now)
    policy_term_years = [10, 15, 20, 25].sample
    policy_end_date = policy_start_date + policy_term_years.years
    premium_payment_term = [policy_term_years, policy_term_years - 5].min

    # Set autopay dates for upcoming installments
    autopay_start_date = policy_start_date + rand(1..11).months
    autopay_end_date = policy_start_date + premium_payment_term.years

    net_premium = [15000, 25000, 50000, 75000, 100000, 150000].sample
    first_year_gst = 18
    total_premium = net_premium + (net_premium * first_year_gst / 100)
    commission_percentage = rand(20..40)
    commission_amount = net_premium * commission_percentage / 100

    life_insurance = LifeInsurance.create!(
      customer: customer,
      sub_agent: sub_agents.sample,
      agency_code: agency_codes.find_by(insurance_type: 'Life'),
      broker: brokers.sample,
      policy_holder: customer.display_name,
      insured_name: customer.display_name,
      insurance_company_name: ['LIC of India', 'SBI Life Insurance', 'HDFC Life Insurance', 'ICICI Prudential Life Insurance'].sample,
      plan_name: "Life Protection Plan #{j + 1}",
      policy_number: "LIF#{Time.current.year}#{i.to_s.rjust(3, '0')}#{j.to_s.rjust(2, '0')}",
      policy_type: ['New', 'Renewal'].sample,
      policy_booking_date: policy_start_date - rand(1..30).days,
      policy_start_date: policy_start_date,
      policy_end_date: policy_end_date,
      risk_start_date: policy_start_date,
      policy_term: policy_term_years,
      premium_payment_term: premium_payment_term,
      payment_mode: ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'].sample,
      sum_insured: [500000, 1000000, 2000000, 3000000, 5000000].sample,
      net_premium: net_premium,
      first_year_gst_percentage: first_year_gst,
      second_year_gst_percentage: 0,
      third_year_gst_percentage: 0,
      total_premium: total_premium,
      nominee_name: customer.nominee_name || "Life Nominee #{i + 1}",
      nominee_relationship: ['Spouse', 'Son', 'Daughter', 'Father', 'Mother'].sample,
      nominee_age: rand(18..60),
      bank_name: "HDFC Bank",
      account_type: "Savings",
      account_number: "123456789#{i}",
      ifsc_code: "HDFC0000001",
      account_holder_name: customer.display_name,
      reference_by_name: "Reference #{i + 1}",
      broker_name: brokers.sample.name,
      bonus: rand(0..50000),
      fund: rand(0..100000),
      main_agent_commission_percentage: commission_percentage,
      commission_amount: commission_amount,
      tds_percentage: 10,
      tds_amount: commission_amount * 0.1,
      after_tds_value: commission_amount * 0.9,
      installment_autopay_start_date: autopay_start_date,
      installment_autopay_end_date: autopay_end_date,
      extra_note: "Life insurance policy for #{customer.display_name}",
      active: true,

      # Rider amounts
      term_rider_amount: rand(0..100000),
      critical_illness_rider_amount: rand(0..500000),
      accident_rider_amount: rand(0..200000),
      pwb_rider_amount: rand(0..150000),
      other_rider_amount: rand(0..75000),

      # Rider notes
      term_rider_note: "Term rider coverage",
      critical_illness_rider_note: "Critical illness protection",
      accident_rider_note: "Accidental death benefit",
      pwb_rider_note: "Premium waiver benefit",
      other_rider_note: "Other rider benefits"
    )

    life_insurances << life_insurance
  end
end

# Create some additional test data with specific dates for installments
puts "📅 Creating specific installment test data..."

# Create a customer specifically for upcoming installments testing
test_customer = Customer.create!(
  customer_type: 'individual',
  first_name: "InstallmentTest",
  last_name: "Customer",
  email: "installment.test@example.com",
  mobile: "9876543210",
  address: "Test Address",
  state: "Maharashtra",
  city: "Mumbai",
  pincode: "400001",
  birth_date: 30.years.ago,
  age: 30,
  gender: 'Male',
  education: 'Graduate',
  marital_status: 'Married',
  occupation: 'Service',
  annual_income: 600000,
  pan_number: "TESTPAN123F",
  status: true,
  added_by: "admin"
)

# Health insurance with monthly installments due soon
HealthInsurance.create!(
  customer: test_customer,
  sub_agent: sub_agents.first,
  policy_holder: test_customer.display_name,
  insurance_company_name: "Star Health Insurance",
  plan_name: "Monthly Installment Health Plan",
  policy_number: "HLT_MONTHLY_TEST_001",
  insurance_type: 'Individual',
  policy_type: 'New',
  policy_booking_date: 6.months.ago,
  policy_start_date: 6.months.ago,
  policy_end_date: 6.months.from_now,
  payment_mode: 'Monthly',
  sum_insured: 500000,
  net_premium: 24000,
  gst_percentage: 18,
  total_premium: 28320,
  main_agent_commission_percentage: 20,
  commission_amount: 4800,
  installment_autopay_start_date: 1.week.from_now, # Due soon
  installment_autopay_end_date: 6.months.from_now
)

# Health insurance with quarterly installments due soon
HealthInsurance.create!(
  customer: test_customer,
  sub_agent: sub_agents.first,
  policy_holder: test_customer.display_name,
  insurance_company_name: "HDFC ERGO Health Insurance",
  plan_name: "Quarterly Installment Health Plan",
  policy_number: "HLT_QUARTERLY_TEST_001",
  insurance_type: 'Family Floater',
  policy_type: 'Renewal',
  policy_booking_date: 8.months.ago,
  policy_start_date: 8.months.ago,
  policy_end_date: 4.months.from_now,
  payment_mode: 'Quarterly',
  sum_insured: 1000000,
  net_premium: 36000,
  gst_percentage: 18,
  total_premium: 42480,
  main_agent_commission_percentage: 22,
  commission_amount: 7920,
  installment_autopay_start_date: 2.weeks.from_now, # Due soon
  installment_autopay_end_date: 4.months.from_now
)

# Life insurance with monthly installments due soon
LifeInsurance.create!(
  customer: test_customer,
  sub_agent: sub_agents.first,
  policy_holder: test_customer.display_name,
  insured_name: test_customer.display_name,
  insurance_company_name: "LIC of India",
  plan_name: "Monthly Installment Life Plan",
  policy_number: "LIF_MONTHLY_TEST_001",
  policy_type: 'New',
  policy_booking_date: 1.year.ago,
  policy_start_date: 1.year.ago,
  policy_end_date: 19.years.from_now,
  policy_term: 20,
  premium_payment_term: 15,
  payment_mode: 'Monthly',
  sum_insured: 2000000,
  net_premium: 60000,
  first_year_gst_percentage: 18,
  total_premium: 70800,
  nominee_name: "Test Nominee",
  nominee_relationship: 'Spouse',
  nominee_age: 28,
  main_agent_commission_percentage: 25,
  commission_amount: 15000,
  installment_autopay_start_date: 3.days.from_now, # Due very soon
  installment_autopay_end_date: 14.years.from_now,
  active: true
)

# Create some policies expiring soon for renewals API
puts "🔄 Creating policies for renewals testing..."

# Health insurance expiring in 15 days
HealthInsurance.create!(
  customer: test_customer,
  sub_agent: sub_agents.first,
  policy_holder: test_customer.display_name,
  insurance_company_name: "Care Health Insurance",
  plan_name: "Expiring Health Plan",
  policy_number: "HLT_EXPIRING_TEST_001",
  insurance_type: 'Individual',
  policy_type: 'Renewal',
  policy_booking_date: 11.months.ago,
  policy_start_date: 11.months.ago,
  policy_end_date: 15.days.from_now, # Expiring soon
  payment_mode: 'Yearly',
  sum_insured: 750000,
  net_premium: 30000,
  gst_percentage: 18,
  total_premium: 35400,
  main_agent_commission_percentage: 18,
  commission_amount: 5400
)

# Life insurance expiring in 45 days
LifeInsurance.create!(
  customer: test_customer,
  sub_agent: sub_agents.first,
  policy_holder: test_customer.display_name,
  insured_name: test_customer.display_name,
  insurance_company_name: "HDFC Life Insurance",
  plan_name: "Expiring Life Plan",
  policy_number: "LIF_EXPIRING_TEST_001",
  policy_type: 'Renewal',
  policy_booking_date: 15.years.ago,
  policy_start_date: 15.years.ago,
  policy_end_date: 45.days.from_now, # Expiring soon
  policy_term: 15,
  premium_payment_term: 10,
  payment_mode: 'Yearly',
  sum_insured: 1500000,
  net_premium: 45000,
  first_year_gst_percentage: 18,
  total_premium: 53100,
  nominee_name: "Expiring Test Nominee",
  nominee_relationship: 'Spouse',
  nominee_age: 35,
  main_agent_commission_percentage: 20,
  commission_amount: 9000,
  active: true
)

puts "✅ Comprehensive mobile API seed data created successfully!"
puts ""
puts "📊 Summary:"
puts "- Created #{SubAgent.count} Sub Agents"
puts "- Created #{Broker.count} Brokers"
puts "- Created #{AgencyCode.count} Agency Codes"
puts "- Created #{Customer.count} Customers"
puts "- Created #{FamilyMember.count} Family Members"
puts "- Created #{HealthInsurance.count} Health Insurance Policies"
puts "- Created #{LifeInsurance.count} Life Insurance Policies"
puts "- Created #{HealthInsuranceMember.count} Health Insurance Members"
puts ""
puts "🎯 Test Scenarios Created:"
puts "- Portfolio API: All customers have multiple policies"
puts "- Upcoming Installments API: Policies with autopay dates set"
puts "- Upcoming Renewals API: Policies expiring in 15-45 days"
puts "- Settings Profile API: Complete customer profiles"
puts "- Agent Dashboard API: Comprehensive agent and policy data"
puts ""
puts "🧪 Test Customer for Mobile APIs:"
puts "- Email: installment.test@example.com"
puts "- Mobile: 9876543210"
puts "- Has policies with upcoming installments and renewals"
puts ""
puts "🔥 Ready to test all mobile APIs!"