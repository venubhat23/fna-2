#!/usr/bin/env ruby
# Script to populate installment_autopay_start_date for existing policies

puts "=== Populating Installment Autopay Start Dates ==="

# Update Health Insurance policies
health_policies = HealthInsurance.where(installment_autopay_start_date: nil)
puts "Found #{health_policies.count} Health Insurance policies without installment_autopay_start_date"

health_policies.each do |policy|
  # Set autopay start date based on payment mode
  autopay_start_date = case policy.payment_mode.to_s.downcase
  when 'monthly'
    policy.policy_start_date + 1.month
  when 'quarterly'
    policy.policy_start_date + 3.months
  when 'half-yearly', 'half yearly'
    policy.policy_start_date + 6.months
  when 'yearly'
    policy.policy_start_date + 1.year
  else
    policy.policy_start_date + 1.month # Default to monthly
  end

  policy.update!(installment_autopay_start_date: autopay_start_date)
  puts "Updated Health Insurance ##{policy.id} - Next autopay: #{autopay_start_date} (#{policy.payment_mode})"
end

# Update Life Insurance policies
life_policies = LifeInsurance.where(installment_autopay_start_date: nil)
puts "\nFound #{life_policies.count} Life Insurance policies without installment_autopay_start_date"

life_policies.each do |policy|
  # Set autopay start date based on payment mode
  autopay_start_date = case policy.payment_mode.to_s.downcase
  when 'monthly'
    policy.policy_start_date + 1.month
  when 'quarterly'
    policy.policy_start_date + 3.months
  when 'half-yearly', 'half yearly'
    policy.policy_start_date + 6.months
  when 'yearly'
    policy.policy_start_date + 1.year
  else
    policy.policy_start_date + 1.month # Default to monthly
  end

  policy.update!(installment_autopay_start_date: autopay_start_date)
  puts "Updated Life Insurance ##{policy.id} - Next autopay: #{autopay_start_date} (#{policy.payment_mode})"
end

puts "\n=== Script Completed ==="

# Show summary for customer 5
puts "\n=== Customer 5 Summary ==="
customer_5_health = HealthInsurance.where(customer_id: 5)
customer_5_life = LifeInsurance.where(customer_id: 5)

puts "Customer 5 Health Insurance policies with upcoming installments:"
customer_5_health.each do |policy|
  if policy.installment_autopay_start_date.present? && policy.installment_autopay_start_date <= 30.days.from_now
    puts "  Policy ##{policy.id}: #{policy.plan_name} - Next: #{policy.installment_autopay_start_date}"
  end
end

puts "Customer 5 Life Insurance policies with upcoming installments:"
customer_5_life.each do |policy|
  if policy.installment_autopay_start_date.present? && policy.installment_autopay_start_date <= 30.days.from_now
    puts "  Policy ##{policy.id}: #{policy.plan_name} - Next: #{policy.installment_autopay_start_date}"
  end
end