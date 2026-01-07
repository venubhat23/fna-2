# Create a test Health Insurance policy with monthly payments for customer 662
customer = Customer.find(662)

# Get default distributor for health insurance if needed
default_distributor = Distributor.first

health_policy = HealthInsurance.create!(
  customer_id: customer.id,
  policy_holder: customer.display_name || 'Self',
  plan_name: 'Monthly Health Plan - Test',
  insurance_company_name: 'Star Health Allied Insurance Co Ltd',
  insurance_type: 'Individual',
  policy_type: 'New',
  policy_number: "MONTHLY-#{Time.current.to_i}",
  policy_booking_date: Date.current,
  policy_start_date: Date.current,
  policy_end_date: 1.year.from_now,
  payment_mode: 'Monthly',
  sum_insured: 500000,
  net_premium: 25000,
  total_premium: 25000,
  gst_percentage: 18,
  installment_autopay_start_date: Date.current,
  distributor_id: default_distributor&.id,
  is_customer_added: false,
  is_agent_added: false,
  is_admin_added: true
)

puts 'Created test Health Insurance policy with monthly payments:'
puts "Policy ID: #{health_policy.id}"
puts "Policy Number: #{health_policy.policy_number}"
puts "Payment Mode: #{health_policy.payment_mode}"
puts "Start Date: #{health_policy.policy_start_date}"
puts "Autopay Start: #{health_policy.installment_autopay_start_date}"
puts "Total Premium: #{health_policy.total_premium}"

# Calculate what the next installment should be
next_installment = health_policy.installment_autopay_start_date + 1.month
monthly_amount = health_policy.total_premium / 12.0

puts "\nNext Installment Date: #{next_installment}"
puts "Monthly Amount: #{monthly_amount.round(2)}"
puts "Days until next installment: #{(next_installment - Date.current).to_i}"