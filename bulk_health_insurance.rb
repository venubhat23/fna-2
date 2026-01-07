# Bulk Health Insurance Data Generator
customer = User.find_by(email: 'customer@example.com')
puts "Creating bulk health insurance policies for customer: #{customer.email}"

health_companies = ['ICICI Lombard', 'Star Health Insurance', 'HDFC ERGO', 'Bajaj Allianz', 'New India Assurance',
                   'United India Insurance', 'Oriental Insurance', 'National Insurance', 'Care Health Insurance',
                   'Max Bupa Health Insurance', 'Religare Health Insurance', 'Apollo Munich Health Insurance']

insurance_types = ['Individual', 'Family', 'Senior Citizen', 'Group']
policy_types = ['New', 'Renewal', 'Port']
plan_names = ['Premium Health Plan', 'Standard Health Plan', 'Basic Health Plan', 'Super Premium Plan',
              'Family Floater Plan', 'Individual Health Plan', 'Senior Citizen Plan', 'Critical Illness Plan']
payment_modes = ['Yearly', 'Half Yearly', 'Quarterly', 'Monthly']

25.times do |i|
  policy = HealthInsurance.create!(
    customer_id: customer.id,
    policy_holder: ['Self', 'Spouse', 'Father', 'Mother'].sample,
    plan_name: plan_names.sample,
    insurance_company_name: health_companies.sample,
    insurance_type: insurance_types.sample,
    policy_type: policy_types.sample,
    policy_number: "HI#{Time.current.to_i + i}#{rand(1000..9999)}",
    policy_booking_date: rand(2.years.ago..Date.current),
    policy_start_date: rand(1.year.ago..Date.current),
    policy_end_date: rand(Date.current..2.years.from_now),
    payment_mode: payment_modes.sample,
    sum_insured: [300000, 500000, 1000000, 1500000, 2000000, 2500000, 3000000, 5000000].sample,
    net_premium: rand(15000..50000),
    total_premium: rand(15000..55000),
    gst_percentage: [18, 12].sample,
    added_by: ['customer_request', 'agent_added', 'admin_added'].sample,
    is_customer_added: [true, false].sample,
    is_agent_added: [true, false].sample,
    is_admin_added: [true, false].sample
  )
  puts "Created Health Insurance Policy #{i+1}: #{policy.policy_number} - #{policy.plan_name}"
end

puts "✅ Successfully created 25 health insurance policies!"