# Create a test Life Insurance policy with quarterly payments for customer 662
customer = Customer.find(662)

# Get default distributor and investor
default_distributor = Distributor.first
default_investor = Investor.first

# Set autopay start date to 2 months ago so next installment is due soon
autopay_start_date = 2.months.ago

life_policy = LifeInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name || 'Self',
  plan_name: 'Quarterly Life Plan - Test',
  insurance_company_name: 'Bajaj Allianz General Insurance Company Limited',
  policy_type: 'New',
  policy_number: "QUARTERLY-#{Time.current.to_i}",
  policy_booking_date: autopay_start_date.to_date,
  policy_start_date: autopay_start_date.to_date,
  policy_end_date: 20.years.from_now,
  payment_mode: 'Quarterly',
  policy_term: 20,
  premium_payment_term: 10,
  sum_insured: 1000000,
  net_premium: 40000,
  total_premium: 40000,
  first_year_gst_percentage: 18,
  installment_autopay_start_date: autopay_start_date.to_date,
  distributor_id: default_distributor&.id,
  investor_id: default_investor&.id,
  is_customer_added: false,
  is_agent_added: false,
  is_admin_added: true
)

puts 'Created test Life Insurance policy with quarterly payments:'
puts "Policy ID: #{life_policy.id}"
puts "Policy Number: #{life_policy.policy_number}"
puts "Payment Mode: #{life_policy.payment_mode}"
puts "Start Date: #{life_policy.policy_start_date}"
puts "Autopay Start: #{life_policy.installment_autopay_start_date}"
puts "Total Premium: #{life_policy.total_premium}"

# Calculate what the next installment should be
first_installment = life_policy.installment_autopay_start_date + 3.months
# If that's in the past, find the next future installment
next_installment = first_installment
while next_installment < Date.current
  next_installment = next_installment + 3.months
end

quarterly_amount = life_policy.total_premium / 4.0

puts "\nNext Installment Date: #{next_installment}"
puts "Quarterly Amount: #{quarterly_amount.round(2)}"
puts "Days until next installment: #{(next_installment - Date.current).to_i}"