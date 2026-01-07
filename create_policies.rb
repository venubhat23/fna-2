puts 'Creating health and life insurance policies...'
agent = User.find_by(email: 'test.agent@example.com')
customers = Customer.where(added_by: agent.id).limit(15)

health_companies = ['Star Health Allied Insurance Co Ltd', 'Care Health Insurance Ltd', 'Niva Bupa Health Insurance Co Ltd', 'Aditya Birla Health Insurance Co Ltd']
life_companies = ['Acko General Insurance Limited', 'ICICI Prudential Life Insurance Co Ltd', 'Bajaj Allianz General Insurance Company Limited', 'HDFC ERGO General Insurance Co Ltd']

policies_created = []

customers.each_with_index do |customer, i|
  # Create Health Insurance Policy
  begin
    health_policy = HealthInsurance.create!(
      customer_id: customer.id,
      policy_holder: customer.display_name,
      plan_name: "Health Plan #{i+1}",
      insurance_company_name: health_companies.sample,
      insurance_type: ['Individual', 'Family Floater', 'Group'].sample,
      policy_type: ['New', 'Renewal'].sample,
      policy_number: "HLT#{Time.current.to_i}#{sprintf('%03d', i+1)}",
      policy_booking_date: Date.current - rand(30).days,
      policy_start_date: Date.current,
      policy_end_date: 1.year.from_now,
      payment_mode: ['Yearly', 'Half Yearly', 'Quarterly', 'Monthly'].sample,
      sum_insured: [300000, 500000, 1000000, 1500000].sample,
      net_premium: [15000, 25000, 35000, 45000].sample,
      total_premium: 25000 + rand(20000),
      gst_percentage: 18,
      is_customer_added: false,
      is_agent_added: true,
      is_admin_added: false
    )

    policies_created << "✅ Health: #{health_policy.policy_number} - #{customer.display_name}"
    puts "✅ Health Policy: #{health_policy.policy_number} for #{customer.display_name}"
  rescue => e
    puts "❌ Health policy failed for #{customer.display_name}: #{e.message}"
  end

  # Create Life Insurance Policy for every customer
  begin
    life_policy = LifeInsurance.create!(
      customer_id: customer.id,
      policy_holder: customer.display_name,
      insured_name: customer.display_name,
      plan_name: "Life Plan #{i+1}",
      insurance_company_name: life_companies.sample,
      policy_type: ['New', 'Renewal'].sample,
      policy_number: "LIF#{Time.current.to_i}#{sprintf('%03d', i+1)}",
      policy_booking_date: Date.current - rand(30).days,
      policy_start_date: Date.current,
      policy_end_date: 10.years.from_now,
      payment_mode: ['Yearly', 'Half Yearly', 'Quarterly', 'Monthly'].sample,
      sum_insured: [500000, 1000000, 2000000, 5000000].sample,
      net_premium: [20000, 35000, 50000, 75000].sample,
      total_premium: 30000 + rand(50000),
      first_year_gst_percentage: 18,
      policy_term: 10,
      premium_payment_term: 10,
      is_customer_added: false,
      is_agent_added: true,
      is_admin_added: false,
      active: true
    )

    policies_created << "✅ Life: #{life_policy.policy_number} - #{customer.display_name}"
    puts "✅ Life Policy: #{life_policy.policy_number} for #{customer.display_name}"
  rescue => e
    puts "❌ Life policy failed for #{customer.display_name}: #{e.message}"
  end
end

puts "\n📊 Final Summary:"
puts "Total policies created: #{policies_created.length}"
puts "Agent ID: #{agent.id}"