#!/usr/bin/env ruby
# Customer Portfolio Mock Data Generator for newcustomer@example.com
# This script creates comprehensive portfolio data for testing mobile APIs

require_relative 'config/environment'

class CustomerPortfolioMockData
  def initialize
    @customer = find_or_create_customer
    @companies = get_insurance_companies
    puts "Generating portfolio data for customer: #{@customer.full_name}"
  end

  def generate_all_data
    puts "\n=== Generating Customer Portfolio Data ==="

    # Generate family members
    generate_family_members

    # Generate health insurance policies
    generate_health_policies

    # Generate life insurance policies
    generate_life_policies

    # Generate policy requests (for customer add policy feature)
    generate_policy_requests

    puts "\n=== Portfolio Data Generation Complete ==="
    display_summary
  end

  private

  def find_or_create_customer
    customer = Customer.find_by(email: 'newcustomer@example.com')

    unless customer
      puts "Creating new customer with email: newcustomer@example.com"
      customer = Customer.create!(
        customer_type: 'individual',
        first_name: 'New',
        last_name: 'Customer',
        email: 'newcustomer@example.com',
        mobile: '9876543220',
        gender: 'Male',
        birth_date: Date.new(1990, 5, 15),
        address: '123 Mock Street, Test Area',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
        pan_no: 'NEWCU1234P',
        occupation: 'Software Engineer',
        annual_income: '1200000',
        marital_status: 'Married',
        status: true
      )
    end

    customer
  end

  def get_insurance_companies
    # Get companies from concern or fallback to common ones
    if defined?(InsuranceCompanyConstants)
      return HealthInsurance.insurance_company_names
    else
      return [
        'Star Health Allied Insurance Co Ltd',
        'Care Health Insurance Ltd',
        'HDFC ERGO General Insurance Co Ltd',
        'Bajaj Allianz General Insurance Company Limited',
        'The New India Assurance Co Ltd'
      ]
    end
  end

  def life_insurance_companies
    # Use companies from the constants that might work for life insurance
    # Since there are no specific life insurance companies in the list,
    # we'll use general companies that are typically multi-line insurers
    if defined?(InsuranceCompanyConstants)
      return LifeInsurance.insurance_company_names rescue get_general_companies_for_life
    else
      return get_general_companies_for_life
    end
  end

  def get_general_companies_for_life
    [
      'ICICI Prudential Life Insurance Co Ltd',
      'Bajaj Allianz General Insurance Company Limited',
      'Tata AIG General Insurance Co Ltd',
      'HDFC ERGO General Insurance Co Ltd',
      'The New India Assurance Co Ltd'
    ]
  end

  def generate_family_members
    puts "Generating family members..."

    # Clear existing family members for clean data
    @customer.family_members.destroy_all

    family_members_data = [
      {
        first_name: 'Priya',
        last_name: 'Customer',
        relationship: 'spouse',
        gender: 'female',
        birth_date: Date.new(1992, 8, 20),
        mobile: '9876543221'
      },
      {
        first_name: 'Arjun',
        last_name: 'Customer',
        relationship: 'child',
        gender: 'male',
        birth_date: Date.new(2018, 3, 10),
        mobile: nil
      },
      {
        first_name: 'Ananya',
        last_name: 'Customer',
        relationship: 'child',
        gender: 'female',
        birth_date: Date.new(2020, 11, 25),
        mobile: nil
      }
    ]

    family_members_data.each do |member_data|
      @customer.family_members.create!(member_data)
      puts "  ✓ Created family member: #{member_data[:first_name]} #{member_data[:last_name]}"
    end
  end

  def generate_health_policies
    puts "Generating health insurance policies..."

    health_policies_data = [
      {
        policy_holder: @customer.full_name,
        plan_name: 'Star Comprehensive Health Plan',
        policy_number: "SHP#{Date.current.year}#{rand(10000..99999)}",
        insurance_company_name: @companies.sample,
        policy_type: 'New',
        insurance_type: 'Family Floater',
        policy_booking_date: 6.months.ago,
        policy_start_date: 6.months.ago,
        policy_end_date: 6.months.from_now,
        payment_mode: 'Yearly',
        sum_insured: 500000.0,
        net_premium: 21186.44,
        gst_percentage: 18.0,
        total_premium: 25000.0,
        main_agent_commission_percentage: 10.0,
        commission_amount: 2500.0,
        tds_percentage: 5.0,
        tds_amount: 125.0,
        after_tds_value: 2375.0
      },
      {
        policy_holder: @customer.full_name,
        plan_name: 'Health Guard Individual Plan',
        policy_number: "HGI#{Date.current.year}#{rand(10000..99999)}",
        insurance_company_name: @companies.sample,
        policy_type: 'Renewal',
        insurance_type: 'Individual',
        policy_booking_date: 1.year.ago,
        policy_start_date: 1.year.ago,
        policy_end_date: 1.month.from_now,
        payment_mode: 'Yearly',
        sum_insured: 300000.0,
        net_premium: 12712.0,
        gst_percentage: 18.0,
        total_premium: 15000.0,
        main_agent_commission_percentage: 8.0,
        commission_amount: 1200.0,
        tds_percentage: 5.0,
        tds_amount: 60.0,
        after_tds_value: 1140.0
      }
    ]

    health_policies_data.each do |policy_data|
      policy = HealthInsurance.create!(policy_data.merge(customer: @customer))

      # Add family members to family floater policy
      if policy.insurance_type == 'Family Floater'
        @customer.family_members.each do |member|
          policy.health_insurance_members.create!(
            member_name: member.full_name,
            relationship: member.relationship,
            age: member.age || ((Date.current - member.birth_date) / 365.25).to_i,
            sum_insured: policy.sum_insured
          )
        end
      end

      puts "  ✓ Created health policy: #{policy.policy_number}"
    end
  end

  def generate_life_policies
    puts "Generating life insurance policies..."

    life_policies_data = [
      {
        policy_holder: @customer.full_name,
        plan_name: 'LIC Jeevan Anand',
        policy_number: "LIC#{Date.current.year}#{rand(100000..999999)}",
        insurance_company_name: life_insurance_companies.sample,
        policy_type: 'New',
        policy_booking_date: 8.months.ago,
        policy_start_date: 8.months.ago,
        policy_end_date: 20.years.from_now,
        payment_mode: 'Yearly',
        policy_term: 20,
        premium_payment_term: 10,
        sum_insured: 1000000.0,
        net_premium: 50000.0,
        first_year_gst_percentage: 18.0,
        second_year_gst_percentage: 4.5,
        third_year_gst_percentage: 4.5,
        total_premium: 59000.0,
        main_agent_commission_percentage: 25.0,
        commission_amount: 12500.0,
        tds_percentage: 5.0,
        tds_amount: 625.0,
        nominee_name: 'Priya Customer',
        nominee_relationship: 'Spouse'
      },
      {
        policy_holder: @customer.full_name,
        plan_name: 'HDFC Click 2 Protect Plus',
        policy_number: "HDFC#{Date.current.year}#{rand(100000..999999)}",
        insurance_company_name: life_insurance_companies.sample,
        policy_type: 'New',
        policy_booking_date: 3.months.ago,
        policy_start_date: 3.months.ago,
        policy_end_date: 30.years.from_now,
        payment_mode: 'Yearly',
        policy_term: 30,
        premium_payment_term: 15,
        sum_insured: 2000000.0,
        net_premium: 18000.0,
        first_year_gst_percentage: 18.0,
        second_year_gst_percentage: 4.5,
        third_year_gst_percentage: 4.5,
        total_premium: 21240.0,
        main_agent_commission_percentage: 30.0,
        commission_amount: 5400.0,
        tds_percentage: 5.0,
        tds_amount: 270.0,
        nominee_name: 'Priya Customer',
        nominee_relationship: 'Spouse'
      }
    ]

    life_policies_data.each do |policy_data|
      policy = LifeInsurance.create!(policy_data.merge(customer: @customer))
      puts "  ✓ Created life policy: #{policy.policy_number}"
    end
  end

  def generate_policy_requests
    puts "Generating policy requests (for customer add policy API)..."

    # These would be stored in a separate table for policy requests
    # For now, we'll create placeholder health and life policies with 'pending' status

    pending_requests = [
      {
        insurance_type: 'health',
        plan_name: 'Preferred Health Plan',
        sum_insured: 1000000,
        premium_amount: 25000,
        insurance_company: @companies.sample,
        renewal_date: 1.year.from_now,
        family_members: ['Spouse', 'Son'],
        remarks: 'Need health insurance for family coverage with individual rooms and cashless facility',
        status: 'pending',
        request_date: 2.weeks.ago
      },
      {
        insurance_type: 'life',
        plan_name: 'Term Life Insurance Plan',
        sum_insured: 5000000,
        premium_amount: 15000,
        insurance_company: life_insurance_companies.sample,
        renewal_date: 25.years.from_now,
        remarks: 'Need term life insurance for family security',
        status: 'pending',
        request_date: 1.week.ago
      }
    ]

    # Store in a simple text file or database table for policy requests
    puts "  ✓ Mock policy requests created (would be stored in policy_requests table)"
  end

  def display_summary
    puts "\n=== Customer Portfolio Summary ==="
    puts "Customer: #{@customer.full_name} (#{@customer.email})"
    puts "Family Members: #{@customer.family_members.count}"
    health_policies = HealthInsurance.where(customer: @customer)
    life_policies = LifeInsurance.where(customer: @customer)
    puts "Health Policies: #{health_policies.count}"
    puts "Life Policies: #{life_policies.count}"
    puts "\n--- Health Policies ---"
    health_policies.each do |policy|
      status = policy.active? ? 'Active' : (policy.expiring_soon? ? 'Expiring Soon' : 'Expired')
      puts "  #{policy.policy_number} - #{policy.plan_name} (#{status})"
      puts "    Sum Insured: ₹#{policy.sum_insured.to_i}"
      puts "    Premium: ₹#{policy.total_premium.to_i}"
      puts "    Expires: #{policy.policy_end_date}"
    end

    puts "\n--- Life Policies ---"
    life_policies.each do |policy|
      status = policy.active? ? 'Active' : (policy.expiring_soon? ? 'Expiring Soon' : 'Expired')
      puts "  #{policy.policy_number} - #{policy.plan_name} (#{status})"
      puts "    Sum Insured: ₹#{policy.sum_insured.to_i}"
      puts "    Premium: ₹#{policy.total_premium.to_i}"
      puts "    Expires: #{policy.policy_end_date}"
    end

    puts "\n--- Upcoming Installments ---"
    upcoming_installments.each do |installment|
      puts "  #{installment[:policy_number]} - ₹#{installment[:amount]} due on #{installment[:due_date]}"
    end

    puts "\n--- Upcoming Renewals ---"
    upcoming_renewals.each do |renewal|
      puts "  #{renewal[:policy_number]} - #{renewal[:policy_type]} expires on #{renewal[:expiry_date]}"
    end
  end

  def upcoming_installments
    # Mock installment data based on policies
    installments = []
    health_policies = HealthInsurance.where(customer: @customer)
    life_policies = LifeInsurance.where(customer: @customer)

    health_policies.each do |policy|
      # Calculate next due date based on payment mode and start date
      next_due_date = case policy.payment_mode.downcase
      when 'yearly'
        policy.policy_start_date + 1.year
      when 'half yearly', 'half-yearly'
        policy.policy_start_date + 6.months
      when 'quarterly'
        policy.policy_start_date + 3.months
      when 'monthly'
        policy.policy_start_date + 1.month
      else
        policy.policy_end_date # Single payment
      end

      if policy.active? && next_due_date && next_due_date <= 3.months.from_now
        installments << {
          policy_number: policy.policy_number,
          policy_type: 'Health Insurance',
          amount: policy.total_premium.to_i,
          due_date: next_due_date,
          status: 'pending'
        }
      end
    end

    life_policies.each do |policy|
      # Calculate next due date based on payment mode and start date
      next_due_date = case policy.payment_mode.downcase
      when 'yearly'
        policy.policy_start_date + 1.year
      when 'half yearly', 'half-yearly'
        policy.policy_start_date + 6.months
      when 'quarterly'
        policy.policy_start_date + 3.months
      when 'monthly'
        policy.policy_start_date + 1.month
      else
        policy.policy_end_date # Single payment
      end

      if policy.active? && next_due_date && next_due_date <= 3.months.from_now
        installments << {
          policy_number: policy.policy_number,
          policy_type: 'Life Insurance',
          amount: policy.total_premium.to_i,
          due_date: next_due_date,
          status: 'pending'
        }
      end
    end

    installments.sort_by { |i| i[:due_date] }
  end

  def upcoming_renewals
    # Mock renewal data for policies expiring in next 60 days
    renewals = []
    health_policies = HealthInsurance.where(customer: @customer)
    life_policies = LifeInsurance.where(customer: @customer)

    health_policies.each do |policy|
      if policy.expiring_soon? || policy.policy_end_date <= 60.days.from_now
        renewals << {
          policy_number: policy.policy_number,
          policy_type: 'Health Insurance',
          plan_name: policy.plan_name,
          expiry_date: policy.policy_end_date,
          sum_insured: policy.sum_insured.to_i,
          current_premium: policy.total_premium.to_i
        }
      end
    end

    life_policies.each do |policy|
      if policy.expiring_soon? || policy.policy_end_date <= 60.days.from_now
        renewals << {
          policy_number: policy.policy_number,
          policy_type: 'Life Insurance',
          plan_name: policy.plan_name,
          expiry_date: policy.policy_end_date,
          sum_insured: policy.sum_insured.to_i,
          current_premium: policy.total_premium.to_i
        }
      end
    end

    renewals.sort_by { |r| r[:expiry_date] }
  end
end

# Run the script
if __FILE__ == $0
  puts "Starting Customer Portfolio Mock Data Generation..."
  generator = CustomerPortfolioMockData.new
  generator.generate_all_data

  puts "\n=== Mock Data Generation Complete ==="
  puts "You can now test the mobile APIs with customer: newcustomer@example.com"
  puts "Password: password123"
end