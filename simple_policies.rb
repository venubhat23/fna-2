# Quick policy creation for testing APIs
puts 'Creating simple policies...'
agent = User.find_by(email: 'test.agent@example.com')
customers = Customer.where(added_by: agent.id).limit(10)

policies_created = 0

customers.each_with_index do |customer, i|
  # Health Policy
  begin
    HealthInsurance.create!(
      customer_id: customer.id,
      policy_holder: customer.display_name,
      plan_name: "Test Health #{i+1}",
      insurance_company_name: 'Star Health Allied Insurance Co Ltd',
      insurance_type: 'Individual',
      policy_type: 'New',
      policy_number: "TH#{i+1}#{Time.current.to_i}",
      policy_booking_date: Date.current,
      policy_start_date: Date.current,
      policy_end_date: 1.year.from_now,
      payment_mode: 'Yearly',
      sum_insured: 500000,
      net_premium: 25000,
      total_premium: 29500,
      gst_percentage: 18,
      is_agent_added: true
    )
    policies_created += 1
    puts "✅ Health policy #{i+1}"
  rescue => e
    puts "❌ Health #{i+1}: #{e.message}"
  end

  # Life Policy
  begin
    LifeInsurance.create!(
      customer_id: customer.id,
      policy_holder: customer.display_name,
      insured_name: customer.display_name,
      plan_name: "Test Life #{i+1}",
      insurance_company_name: 'ICICI Prudential Life Insurance Co Ltd',
      policy_type: 'New',
      policy_number: "TL#{i+1}#{Time.current.to_i}",
      policy_booking_date: Date.current,
      policy_start_date: Date.current,
      policy_end_date: 10.years.from_now,
      payment_mode: 'Yearly',
      sum_insured: 1000000,
      net_premium: 50000,
      total_premium: 59000,
      first_year_gst_percentage: 18,
      policy_term: 10,
      premium_payment_term: 10,
      is_agent_added: true,
      active: true
    )
    policies_created += 1
    puts "✅ Life policy #{i+1}"
  rescue => e
    puts "❌ Life #{i+1}: #{e.message}"
  end
end

puts "\n📊 Total policies: #{policies_created}"