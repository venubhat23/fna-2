#!/usr/bin/env ruby
puts "=== Simple Fix for Upcoming Installments ==="

# The logic: if installment_autopay_start_date + payment_period <= 30.days.from_now

# Health Policy - Monthly (next installment in 15 days)
policy = HealthInsurance.where(customer_id: 5).first
if policy
  # Set start date 15 days ago, so next monthly installment is in 15 days
  policy.update!(
    payment_mode: 'Monthly',
    installment_autopay_start_date: 15.days.ago
  )
  puts "Health Policy ##{policy.id}: Monthly payment, start=#{15.days.ago.strftime('%Y-%m-%d')}"
  puts "  Next installment: #{(15.days.ago + 1.month).strftime('%Y-%m-%d')} (in #{((15.days.ago + 1.month) - Date.current).to_i} days)"
end

# Health Policy - Quarterly (next installment in 25 days)
policy2 = HealthInsurance.where(customer_id: 5).offset(1).first
if policy2
  # Set start date so next quarterly installment is in 25 days
  start_date = 25.days.from_now - 3.months
  policy2.update!(
    payment_mode: 'Quarterly',
    installment_autopay_start_date: start_date
  )
  puts "Health Policy ##{policy2.id}: Quarterly payment, start=#{start_date.strftime('%Y-%m-%d')}"
  puts "  Next installment: #{(start_date + 3.months).strftime('%Y-%m-%d')} (in #{((start_date + 3.months) - Date.current).to_i} days)"
end

# Life Policy - Half-yearly (next installment in 10 days)
life_policy = LifeInsurance.where(customer_id: 5).first
if life_policy
  # Set start date so next half-yearly installment is in 10 days
  start_date = 10.days.from_now - 6.months
  life_policy.update!(
    payment_mode: 'Half-Yearly',
    installment_autopay_start_date: start_date
  )
  puts "Life Policy ##{life_policy.id}: Half-Yearly payment, start=#{start_date.strftime('%Y-%m-%d')}"
  puts "  Next installment: #{(start_date + 6.months).strftime('%Y-%m-%d')} (in #{((start_date + 6.months) - Date.current).to_i} days)"
end

puts "\n=== Verification ==="
puts "Checking dates that should appear in upcoming installments:"
puts "- #{(15.days.ago + 1.month).strftime('%Y-%m-%d')} (#{((15.days.ago + 1.month) - Date.current).to_i} days from now)"
puts "- #{(25.days.from_now - 3.months + 3.months).strftime('%Y-%m-%d')} (#{((25.days.from_now - 3.months + 3.months) - Date.current).to_i} days from now)"
puts "- #{(10.days.from_now - 6.months + 6.months).strftime('%Y-%m-%d')} (#{((10.days.from_now - 6.months + 6.months) - Date.current).to_i} days from now)"