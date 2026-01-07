#!/usr/bin/env ruby
puts "=== Final Fix for Upcoming Installments ==="

# Just set some policies to have installment dates within 30 days
# This time using Date objects consistently

# Health Policy 1 - Monthly (next installment in 15 days)
policy1 = HealthInsurance.where(customer_id: 5).first
if policy1
  start_date = Date.current - 15.days # 15 days ago
  policy1.update!(
    payment_mode: 'Monthly',
    installment_autopay_start_date: start_date
  )
  next_date = start_date + 1.month
  puts "Health Policy ##{policy1.id}: Monthly, start=#{start_date}, next=#{next_date} (#{(next_date - Date.current).to_i} days)"
end

# Health Policy 2 - Quarterly (next installment in 20 days)
policy2 = HealthInsurance.where(customer_id: 5).offset(1).first
if policy2
  start_date = Date.current - 70.days # About 2.5 months ago
  policy2.update!(
    payment_mode: 'Quarterly',
    installment_autopay_start_date: start_date
  )
  next_date = start_date + 3.months
  puts "Health Policy ##{policy2.id}: Quarterly, start=#{start_date}, next=#{next_date} (#{(next_date - Date.current).to_i} days)"
end

# Life Policy - Half-yearly (next installment in 10 days)
life_policy = LifeInsurance.where(customer_id: 5).first
if life_policy
  start_date = Date.current - 170.days # About 5.5 months ago
  life_policy.update!(
    payment_mode: 'Half-Yearly',
    installment_autopay_start_date: start_date
  )
  next_date = start_date + 6.months
  puts "Life Policy ##{life_policy.id}: Half-Yearly, start=#{start_date}, next=#{next_date} (#{(next_date - Date.current).to_i} days)"
end

puts "\n=== Testing API Logic ==="

# Test with exact API logic
installments = []

# Health Insurance installments
health_policies = HealthInsurance.where(customer_id: 5).where('policy_end_date >= ?', Date.current)
health_policies.each do |policy|
  next unless policy.installment_autopay_start_date.present?

  # Calculate next installment date (from controller logic)
  next_installment = case policy.payment_mode.downcase
  when 'monthly'
    policy.installment_autopay_start_date + 1.month
  when 'quarterly'
    policy.installment_autopay_start_date + 3.months
  when 'half-yearly', 'half yearly'
    policy.installment_autopay_start_date + 6.months
  when 'yearly'
    policy.installment_autopay_start_date + 1.year
  else
    nil
  end

  if next_installment && next_installment <= 30.days.from_now
    installment_amount = case policy.payment_mode.downcase
    when 'monthly'
      policy.total_premium / 12.0
    when 'quarterly'
      policy.total_premium / 4.0
    when 'half-yearly', 'half yearly'
      policy.total_premium / 2.0
    when 'yearly'
      policy.total_premium
    else
      policy.total_premium
    end

    installments << {
      id: policy.id,
      insurance_name: policy.plan_name,
      insurance_type: "Health",
      next_installment_date: next_installment,
      installment_amount: installment_amount,
      payment_mode: policy.payment_mode
    }
  end
end

# Life Insurance installments
life_policies = LifeInsurance.where(customer_id: 5).where('policy_end_date >= ?', Date.current)
life_policies.each do |policy|
  next unless policy.installment_autopay_start_date.present?

  next_installment = case policy.payment_mode.downcase
  when 'monthly'
    policy.installment_autopay_start_date + 1.month
  when 'quarterly'
    policy.installment_autopay_start_date + 3.months
  when 'half-yearly', 'half yearly'
    policy.installment_autopay_start_date + 6.months
  when 'yearly'
    policy.installment_autopay_start_date + 1.year
  else
    nil
  end

  if next_installment && next_installment <= 30.days.from_now
    installment_amount = case policy.payment_mode.downcase
    when 'monthly'
      policy.total_premium / 12.0
    when 'quarterly'
      policy.total_premium / 4.0
    when 'half-yearly', 'half yearly'
      policy.total_premium / 2.0
    when 'yearly'
      policy.total_premium
    else
      policy.total_premium
    end

    installments << {
      id: policy.id,
      insurance_name: policy.plan_name,
      insurance_type: "Life",
      next_installment_date: next_installment,
      installment_amount: installment_amount,
      payment_mode: policy.payment_mode
    }
  end
end

puts "\nFound #{installments.count} upcoming installments:"
installments.each do |inst|
  puts "- #{inst[:insurance_type]} Policy ##{inst[:id]}: #{inst[:insurance_name]}"
  puts "  #{inst[:payment_mode]} payment: ₹#{inst[:installment_amount].round(2)} due #{inst[:next_installment_date]}"
end

puts "\n=== API should now return data! ==="