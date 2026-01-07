# Create a test Health Insurance policy with an installment due in 5 days
customer = Customer.find(662)
default_distributor = Distributor.first

# Set autopay start date so that next installment is due in 5 days
# For monthly payments, if we set start date to 25 days ago, next payment will be in 5 days
autopay_start_date = 25.days.ago

health_policy = HealthInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name || 'Self',
  plan_name: 'Soon Due Health Plan - Test',
  insurance_company_name: 'Star Health Allied Insurance Co Ltd',
  insurance_type: 'Individual',
  policy_type: 'New',
  policy_number: "SOONDUE-#{Time.current.to_i}",
  policy_booking_date: autopay_start_date.to_date,
  policy_start_date: autopay_start_date.to_date,
  policy_end_date: 1.year.from_now,
  payment_mode: 'Monthly',
  sum_insured: 300000,
  net_premium: 15000,
  total_premium: 15000,
  gst_percentage: 18,
  installment_autopay_start_date: autopay_start_date.to_date,
  distributor_id: default_distributor&.id,
  is_customer_added: false,
  is_agent_added: false,
  is_admin_added: true
)

puts 'Created test Health Insurance policy with installment due soon:'
puts "Policy ID: #{health_policy.id}"
puts "Policy Number: #{health_policy.policy_number}"
puts "Payment Mode: #{health_policy.payment_mode}"
puts "Start Date: #{health_policy.policy_start_date}"
puts "Autopay Start: #{health_policy.installment_autopay_start_date}"
puts "Total Premium: #{health_policy.total_premium}"

# Calculate what the next installment should be
first_installment = health_policy.installment_autopay_start_date + 1.month
monthly_amount = health_policy.total_premium / 12.0

puts "\nNext Installment Date: #{first_installment}"
puts "Monthly Amount: #{monthly_amount.round(2)}"
puts "Days until next installment: #{(first_installment - Date.current).to_i}"