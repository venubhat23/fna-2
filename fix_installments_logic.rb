#!/usr/bin/env ruby
puts "=== Fixing Installment Logic for Customer 5 ==="

# The key insight: installment_autopay_start_date should be the NEXT due date,
# not a past date to calculate from

# Update health policies
customer_5_health = HealthInsurance.where(customer_id: 5).limit(3)
customer_5_health.each_with_index do |policy, i|
  case i
  when 0
    # Next installment due in 5 days
    policy.update!(
      payment_mode: 'Monthly',
      installment_autopay_start_date: 5.days.from_now
    )
    puts "Health Policy ##{policy.id}: Monthly, next due in 5 days (#{5.days.from_now.strftime('%Y-%m-%d')})"
  when 1
    # Next installment due in 20 days
    policy.update!(
      payment_mode: 'Quarterly',
      installment_autopay_start_date: 20.days.from_now
    )
    puts "Health Policy ##{policy.id}: Quarterly, next due in 20 days (#{20.days.from_now.strftime('%Y-%m-%d')})"
  when 2
    # Next installment due in 35 days (should be excluded - beyond 30 days)
    policy.update!(
      payment_mode: 'Yearly',
      installment_autopay_start_date: 35.days.from_now
    )
    puts "Health Policy ##{policy.id}: Yearly, next due in 35 days (#{35.days.from_now.strftime('%Y-%m-%d')}) - should be excluded"
  end
end

# Update life policy
customer_5_life = LifeInsurance.where(customer_id: 5).first
if customer_5_life
  customer_5_life.update!(
    payment_mode: 'Half-Yearly',
    installment_autopay_start_date: 12.days.from_now
  )
  puts "Life Policy ##{customer_5_life.id}: Half-Yearly, next due in 12 days (#{12.days.from_now.strftime('%Y-%m-%d')})"
end

puts "\n=== Now Testing the API Logic ==="

# Simulate the exact API logic
installments = []

# Health Insurance installments (from API code)
health_policies = HealthInsurance.where(customer_id: 5).where('policy_end_date >= ?', Date.current)
health_policies.each do |policy|
  next unless policy.installment_autopay_start_date.present?

  # The API uses this method from the controller
  def calculate_next_installment_date(start_date, payment_mode)
    return nil unless start_date

    case payment_mode.downcase
    when 'monthly'
      start_date + 1.month
    when 'quarterly'
      start_date + 3.months
    when 'half-yearly', 'half yearly'
      start_date + 6.months
    when 'yearly'
      start_date + 1.year
    else
      nil
    end
  end

  # Calculate next installment date based on payment mode
  next_installment = calculate_next_installment_date(policy.installment_autopay_start_date, policy.payment_mode)

  puts "Health Policy ##{policy.id}: start=#{policy.installment_autopay_start_date}, next=#{next_installment}"

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
      insurance_name: policy.plan_name || "Health Insurance",
      insurance_type: "Health",
      policy_number: policy.policy_number,
      next_installment_date: next_installment,
      installment_amount: installment_amount
    }
    puts "  >>> ADDED (within 30 days)"
  else
    puts "  >>> SKIPPED (beyond 30 days or no date)"
  end
end

puts "\nTotal upcoming installments: #{installments.count}"