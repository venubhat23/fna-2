# Sample data for testing renewal and expired policies
puts "Creating sample data for renewal and expired policies..."

# Check if Customer exists
customer = Customer.first
unless customer
  puts "Creating sample customer..."
  customer = Customer.create!(
    first_name: 'John',
    last_name: 'Doe',
    email: 'john.doe@example.com',
    mobile: '9876543210',
    date_of_birth: 30.years.ago,
    customer_type: 'individual',
    city: 'Mumbai',
    state: 'Maharashtra',
    status: true
  )
  puts "✅ Sample customer created: #{customer.display_name}"
else
  puts "✅ Using existing customer: #{customer.display_name}"
end

# Create expired health insurance policies
puts "\nCreating expired health insurance policies..."
3.times do |i|
  policy_number = "EXP-HEALTH-#{Time.current.to_i}-#{i}"

  health_insurance = HealthInsurance.new(
    customer_id: customer.id,
    policy_holder: customer.display_name || 'Self',
    plan_name: ['Basic Health Plan', 'Premium Care', 'Family Shield'][i],
    insurance_company_name: ['Star Health Allied Insurance Co Ltd', 'Care Health Insurance Ltd', 'Niva Bupa Health Insurance Co Ltd'][i],
    insurance_type: 'Individual',
    policy_type: 'New',
    policy_number: policy_number,
    policy_booking_date: (180 + i * 30).days.ago,
    policy_start_date: (180 + i * 30).days.ago,
    policy_end_date: (i * 15 + 10).days.ago, # Already expired
    payment_mode: 'Yearly',
    sum_insured: [500000, 750000, 1000000][i],
    net_premium: [25000, 35000, 45000][i],
    total_premium: [29500, 41300, 53100][i],
    gst_percentage: 18,
    is_customer_added: true
  )

  if health_insurance.save
    puts "✅ Expired health insurance created: #{policy_number}"
  else
    puts "❌ Failed to create expired health insurance: #{health_insurance.errors.full_messages}"
  end
end

# Create upcoming renewal health insurance policies
puts "\nCreating upcoming renewal health insurance policies..."
3.times do |i|
  policy_number = "REN-HEALTH-#{Time.current.to_i}-#{i}"

  health_insurance = HealthInsurance.new(
    customer_id: customer.id,
    policy_holder: customer.display_name || 'Self',
    plan_name: ['Super Health Plan', 'Gold Care', 'Platinum Coverage'][i],
    insurance_company_name: ['Aditya Birla Health Insurance Co Ltd', 'Manipal Cigna Health Insurance Company Limited', 'Star Health Allied Insurance Co Ltd'][i],
    insurance_type: 'Individual',
    policy_type: 'Renewal',
    policy_number: policy_number,
    policy_booking_date: 365.days.ago,
    policy_start_date: 365.days.ago,
    policy_end_date: (i * 10 + 15).days.from_now, # Due for renewal soon
    payment_mode: 'Yearly',
    sum_insured: [600000, 800000, 1200000][i],
    net_premium: [30000, 40000, 50000][i],
    total_premium: [35400, 47200, 59000][i],
    gst_percentage: 18,
    is_customer_added: true
  )

  if health_insurance.save
    puts "✅ Renewal health insurance created: #{policy_number}"
  else
    puts "❌ Failed to create renewal health insurance: #{health_insurance.errors.full_messages}"
  end
end

# Note: Other insurance types can be added later with proper attribute mapping

puts "\n🎉 Sample data creation completed!"
puts "\nYou can now visit:"
puts "- /admin/reports/upcoming_renewal - to see renewal policies"
puts "- /admin/reports/expired_insurance - to see expired policies"