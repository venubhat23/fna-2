class DashboardController < ApplicationController
  skip_load_and_authorize_resource

  def index
    authorize! :read, :dashboard
    load_dashboard_data
  end

  def beautiful
    authorize! :read, :dashboard
    load_dashboard_data
    render 'beautiful_dashboard', layout: false
  end

  def ultra
    authorize! :read, :dashboard
    load_dashboard_data
    render 'ultra_attractive_dashboard', layout: false
  end

  def stats
    authorize! :read, :dashboard
    load_dashboard_data

    render json: {
      # Basic counts
      total_customers: @total_customers,
      active_customers: @active_customers,
      inactive_customers: @inactive_customers,
      total_affiliates: @total_affiliates,
      total_sub_agents: @total_sub_agents,
      total_policies: @total_policies,

      # Financial data
      total_premium_collected: @total_premium_collected,
      total_sum_insured: @total_sum_insured,
      pending_payouts: @pending_payouts,
      paid_payouts: @paid_payouts,
      total_payouts: @total_payouts,

      # Lead metrics
      total_leads: @total_leads,
      converted_leads: @converted_leads,
      pending_leads: @pending_leads,
      lead_conversion_percentage: @lead_conversion_percentage,

      # Policy status
      renewal_due_count: @renewal_due_count,
      expired_policies_count: @expired_policies_count,

      # Charts data
      policy_type_distribution: @policy_type_distribution,

      # Support
      client_requests_count: @client_requests_count,
      support_tickets: @support_tickets,
      commissions_due: @commissions_due,
      new_leads: @new_leads,

      # Performance metrics
      renewal_status: @renewal_status,
      referral_status: @referral_status,
      customer_location: @customer_location,

      # Timestamp
      last_updated: Time.current.strftime('%Y-%m-%d %H:%M:%S'),
      cache_key: "dashboard_#{Time.current.to_i}"
    }
  end

  private

  def load_dashboard_data
    # Optimize with a single query for basic counts
    policy_counts = get_optimized_policy_counts

    # Summary statistics with real data
    @total_customers = Customer.count
    @total_affiliates = SubAgent.count  # Show all SubAgents (not just active ones)
    @total_sub_agents = SubAgent.where(status: 'active').count
    @total_policies = policy_counts[:total_count]

    # Calculate totals from optimized queries
    premium_data = get_optimized_premium_data
    @total_premium_collected = premium_data[:total_premium]
    @total_sum_insured = premium_data[:total_sum_insured]

    # Additional real-time metrics
    @active_customers = Customer.where(status: true).count
    @inactive_customers = @total_customers - @active_customers

    @total_leads = Lead.count
    @converted_leads = Lead.where(current_stage: ['converted', 'policy_created']).count
    @pending_leads = Lead.where(current_stage: ['new', 'contacted', 'consultation', 'one_on_one']).count

    # Lead conversion percentage
    @lead_conversion_percentage = @total_leads > 0 ? ((@converted_leads.to_f / @total_leads) * 100).round(2) : 0

    # Count renewals due (policies expiring within 30 days) - optimized
    thirty_days_from_now = Date.current + 30.days
    @renewal_due_count = get_renewal_due_count(thirty_days_from_now)

    # Expired policies count
    @expired_policies_count = get_expired_policies_count

    # Pending payouts calculation - optimized
    payout_data = get_optimized_payout_data
    @pending_payouts = payout_data[:pending_amount]
    @paid_payouts = payout_data[:paid_amount]
    @total_payouts = payout_data[:total_amount]

    # Policy type distribution for chart with percentages
    @policy_type_distribution = {
      'Health Insurance' => {
        count: policy_counts[:health_count],
        percentage: policy_counts[:total_count] > 0 ? ((policy_counts[:health_count].to_f / policy_counts[:total_count]) * 100).round(2) : 0
      },
      'Life Insurance' => {
        count: policy_counts[:life_count],
        percentage: policy_counts[:total_count] > 0 ? ((policy_counts[:life_count].to_f / policy_counts[:total_count]) * 100).round(2) : 0
      },
      'Motor Insurance' => {
        count: policy_counts[:motor_count],
        percentage: policy_counts[:total_count] > 0 ? ((policy_counts[:motor_count].to_f / policy_counts[:total_count]) * 100).round(2) : 0
      },
      'Other Insurance' => {
        count: policy_counts[:other_count],
        percentage: policy_counts[:total_count] > 0 ? ((policy_counts[:other_count].to_f / policy_counts[:total_count]) * 100).round(2) : 0
      }
    }

    # Premium collection trend by month (last 12 months)
    @premium_collection_trend = {}
    12.times do |i|
      month_date = (Date.current - i.months).beginning_of_month
      month_name = month_date.strftime('%b')

      monthly_premium = HealthInsurance.where(created_at: month_date..(month_date.end_of_month)).sum(:total_premium) +
                        LifeInsurance.where(created_at: month_date..(month_date.end_of_month)).sum(:total_premium) +
                        MotorInsurance.where(created_at: month_date..(month_date.end_of_month)).sum(:total_premium)
                        # OtherInsurance doesn't have total_premium column

      @premium_collection_trend[month_name] = monthly_premium
    end
    @premium_collection_trend = @premium_collection_trend.to_a.reverse.to_h

    # Lead conversion funnel
    @lead_conversion_funnel = {
      'Leads Generated' => Lead.count,
      'Consultation' => Lead.where(current_stage: 'consultation').count,
      'One-on-One' => Lead.where(current_stage: 'one_on_one').count,
      'Converted' => Lead.where(current_stage: 'converted').count,
      'Policy Created' => Lead.where(current_stage: 'policy_created').count
    }

    # Top Affiliate performance - based on actual SubAgent data
    @agent_performance = {}

    # Get all SubAgents with their data
    SubAgent.where(status: 'active').find_each do |sub_agent|
      # Create full name from first_name and last_name
      affiliate_name = "#{sub_agent.first_name} #{sub_agent.last_name}".strip
      affiliate_name = "Affiliate #{sub_agent.id}" if affiliate_name.blank?

      # Calculate total premium from customers linked to this sub agent
      customer_ids = Customer.where(sub_agent: affiliate_name).pluck(:id)

      if customer_ids.any?
        total_premium = HealthInsurance.where(customer_id: customer_ids).sum(:total_premium) +
                       LifeInsurance.where(customer_id: customer_ids).sum(:total_premium) +
                       MotorInsurance.where(customer_id: customer_ids).sum(:total_premium)

        # Add SubAgent name and premium if there's business
        if total_premium > 0
          @agent_performance[affiliate_name] = total_premium
        end
      else
        # If no customers linked, show as potential affiliate
        @agent_performance[affiliate_name] = 0
      end
    end

    # Sort by premium and take top 7
    @agent_performance = @agent_performance.sort_by { |_, v| -v }.first(7).to_h

    # Renewal status overview
    expired_policies = HealthInsurance.where('policy_end_date < ?', Date.current).count +
                      LifeInsurance.where('policy_end_date < ?', Date.current).count +
                      MotorInsurance.where('policy_end_date < ?', Date.current).count +
                      OtherInsurance.where('policy_end_date < ?', Date.current).count

    renewed_policies = HealthInsurance.where(policy_type: 'renewal').count +
                      LifeInsurance.where(policy_type: 'renewal').count +
                      MotorInsurance.where(policy_type: 'renewal').count
                      # OtherInsurance doesn't have policy_type column

    @renewal_status = {
      'Renewed' => renewed_policies,
      'Pending' => @renewal_due_count,
      'Expired' => expired_policies
    }

    # Referral settlement status
    @referral_status = {
      'Paid' => Lead.where(transferred_amount: true).count,
      'Pending' => Lead.where(current_stage: 'converted', transferred_amount: false).count,
      'In-Process' => Lead.where(current_stage: 'policy_created', transferred_amount: false).count
    }

    # Commission summary by month
    @commission_summary = {
      'main_agent' => {},
      'sub_agent' => {},
      'tds' => {}
    }

    12.times do |i|
      month_date = (Date.current - i.months).beginning_of_month
      month_name = month_date.strftime('%b')

      # Get commission data from commission payouts
      main_commission = CommissionPayout.where(
        created_at: month_date..(month_date.end_of_month),
        payout_to: 'main_agent'
      ).sum(:payout_amount)

      sub_commission = CommissionPayout.where(
        created_at: month_date..(month_date.end_of_month),
        payout_to: 'sub_agent'
      ).sum(:payout_amount)

      # Calculate TDS (assuming 10% for demonstration)
      total_commission = main_commission + sub_commission
      tds_amount = total_commission * 0.1

      @commission_summary['main_agent'][month_name] = main_commission
      @commission_summary['sub_agent'][month_name] = sub_commission
      @commission_summary['tds'][month_name] = tds_amount
    end

    # Customer geographic distribution
    @customer_location = Customer.group(:state).count.sort_by { |_, v| -v }.first(8).to_h

    # Customer acquisition trend (last 6 months)
    @customer_acquisition_trend = {}
    6.times do |i|
      month_date = (Date.current - i.months).beginning_of_month
      month_name = month_date.strftime('%b')
      monthly_customers = Customer.where(created_at: month_date..(month_date.end_of_month)).count
      @customer_acquisition_trend[month_name] = monthly_customers
    end
    @customer_acquisition_trend = @customer_acquisition_trend.to_a.reverse.to_h

    # Age Group Distribution for customers
    @age_distribution = calculate_age_distribution

    # Policy Status Distribution
    @policy_status_distribution = calculate_policy_status_distribution

    # Monthly Revenue Breakdown
    @monthly_revenue_breakdown = calculate_monthly_revenue_breakdown

    # Lead Source Analysis
    @lead_source_analysis = Lead.group(:lead_source).count

    # Premium by Insurance Type (for pie chart)
    @premium_by_type = {
      'Health Insurance' => HealthInsurance.sum(:total_premium) || 0,
      'Life Insurance' => LifeInsurance.sum(:total_premium) || 0,
      'Motor Insurance' => MotorInsurance.sum(:total_premium) || 0
    }

    # Daily Activity Trend (last 7 days)
    @daily_activity_trend = {}
    7.times do |i|
      date = i.days.ago.to_date
      day_name = date.strftime('%a')
      daily_count = Customer.where(created_at: date.beginning_of_day..date.end_of_day).count +
                   Lead.where(created_at: date.beginning_of_day..date.end_of_day).count
      @daily_activity_trend[day_name] = daily_count
    end
    @daily_activity_trend = @daily_activity_trend.to_a.reverse.to_h

    # Calculate growth percentages (real-time data)
    calculate_growth_metrics

    # Recent activities for display
    @recent_policies = []
    recent_health = HealthInsurance.includes(:customer).order(created_at: :desc).limit(2)
    recent_life = LifeInsurance.includes(:customer).order(created_at: :desc).limit(2)
    recent_motor = MotorInsurance.includes(:customer).order(created_at: :desc).limit(1)

    @recent_policies = (recent_health + recent_life + recent_motor).sort_by(&:created_at).reverse.first(5)

    @recent_customers = Customer.order(created_at: :desc).limit(5)
    @recent_leads = Lead.order(created_at: :desc).limit(5)

    # Policies expiring soon for renewal section
    @renewal_policies = []
    health_renewals = HealthInsurance.includes(:customer)
                                    .where('policy_end_date BETWEEN ? AND ?', Date.current, thirty_days_from_now)
                                    .order(:policy_end_date)
                                    .limit(5)
    life_renewals = LifeInsurance.includes(:customer)
                                 .where('policy_end_date BETWEEN ? AND ?', Date.current, thirty_days_from_now)
                                 .order(:policy_end_date)
                                 .limit(5)
    motor_renewals = MotorInsurance.includes(:customer)
                                   .where('policy_end_date BETWEEN ? AND ?', Date.current, thirty_days_from_now)
                                   .order(:policy_end_date)
                                   .limit(5)

    @renewal_policies = (health_renewals + life_renewals + motor_renewals).sort_by(&:policy_end_date).first(10)

    # Expired policies for expired section
    @expired_policies = []
    health_expired = HealthInsurance.includes(:customer)
                                   .where('policy_end_date < ?', Date.current)
                                   .order(policy_end_date: :desc)
                                   .limit(5)
    life_expired = LifeInsurance.includes(:customer)
                                .where('policy_end_date < ?', Date.current)
                                .order(policy_end_date: :desc)
                                .limit(5)
    motor_expired = MotorInsurance.includes(:customer)
                                  .where('policy_end_date < ?', Date.current)
                                  .order(policy_end_date: :desc)
                                  .limit(5)

    @expired_policies = (health_expired + life_expired + motor_expired).sort_by(&:policy_end_date).reverse.first(10)

    # Client requests count (if ClientRequest model exists)
    @client_requests_count = ClientRequest.count

    # Additional quick access metrics
    @claims_processing = 0  # Will be updated when claims model is available

    # Count pending documents from all insurance types and customers
    pending_docs = 0
    pending_docs += Customer.joins(:documents).count rescue 0
    pending_docs += HealthInsurance.count rescue 0  # Assuming each needs document verification
    pending_docs += LifeInsurance.count rescue 0
    pending_docs += MotorInsurance.count rescue 0
    @docs_pending = pending_docs

    @commissions_due = CommissionPayout.where(status: 'pending').sum(:payout_amount) || 0
    @new_leads = Lead.where('created_at >= ?', 7.days.ago).count

    # Use ClientRequest as support tickets - count unresolved requests
    @support_tickets = ClientRequest.where(status: ['pending', 'in_progress']).count
  end

  # Optimized helper methods to avoid N+1 queries

  def get_optimized_policy_counts
    # Single query to get all policy counts
    health_count = HealthInsurance.count
    life_count = LifeInsurance.count
    motor_count = MotorInsurance.count rescue 0
    other_count = OtherInsurance.count rescue 0

    {
      health_count: health_count,
      life_count: life_count,
      motor_count: motor_count,
      other_count: other_count,
      total_count: health_count + life_count + motor_count + other_count
    }
  end

  def get_optimized_premium_data
    # Simpler direct sum queries
    health_premium = HealthInsurance.sum(:total_premium) || 0
    life_premium = LifeInsurance.sum(:total_premium) || 0
    motor_premium = begin
      MotorInsurance.sum(:total_premium) || 0
    rescue
      0
    end

    health_sum = HealthInsurance.sum(:sum_insured) || 0
    life_sum = LifeInsurance.sum(:sum_insured) || 0
    motor_sum = begin
      MotorInsurance.sum(:sum_insured) || 0
    rescue
      0
    end

    {
      total_premium: health_premium + life_premium + motor_premium,
      total_sum_insured: health_sum + life_sum + motor_sum
    }
  end

  def get_renewal_due_count(thirty_days_from_now)
    # Single query for renewal counts
    health_renewals = HealthInsurance.where('policy_end_date BETWEEN ? AND ?', Date.current, thirty_days_from_now).count
    life_renewals = LifeInsurance.where('policy_end_date BETWEEN ? AND ?', Date.current, thirty_days_from_now).count

    motor_renewals = begin
      MotorInsurance.where('policy_end_date BETWEEN ? AND ?', Date.current, thirty_days_from_now).count
    rescue
      0
    end

    other_renewals = begin
      OtherInsurance.where('policy_end_date BETWEEN ? AND ?', Date.current, thirty_days_from_now).count
    rescue
      0
    end

    health_renewals + life_renewals + motor_renewals + other_renewals
  end

  def get_expired_policies_count
    # Single query for expired policies
    health_expired = HealthInsurance.where('policy_end_date < ?', Date.current).count
    life_expired = LifeInsurance.where('policy_end_date < ?', Date.current).count

    motor_expired = begin
      MotorInsurance.where('policy_end_date < ?', Date.current).count
    rescue
      0
    end

    other_expired = begin
      OtherInsurance.where('policy_end_date < ?', Date.current).count
    rescue
      0
    end

    health_expired + life_expired + motor_expired + other_expired
  end

  def get_optimized_payout_data
    # Optimized payout queries
    commission_pending = CommissionPayout.where(status: 'pending').sum(:payout_amount) || 0
    commission_paid = CommissionPayout.where(status: 'paid').sum(:payout_amount) || 0
    commission_total = CommissionPayout.sum(:payout_amount) || 0

    distributor_pending = begin
      DistributorPayout.where(status: 'pending').sum(:payout_amount) || 0
    rescue
      0
    end

    distributor_paid = begin
      DistributorPayout.where(status: 'paid').sum(:payout_amount) || 0
    rescue
      0
    end

    distributor_total = begin
      DistributorPayout.sum(:payout_amount) || 0
    rescue
      0
    end

    {
      pending_amount: commission_pending + distributor_pending,
      paid_amount: commission_paid + distributor_paid,
      total_amount: commission_total + distributor_total
    }
  end

  def calculate_growth_metrics
    # Get data for current month and last month
    current_month_start = Date.current.beginning_of_month
    last_month_start = 1.month.ago.beginning_of_month
    last_month_end = 1.month.ago.end_of_month

    # Current month data
    current_customers = Customer.where('created_at >= ?', current_month_start).count
    current_policies = get_policies_count_for_period(current_month_start, Date.current)
    current_premium = get_premium_for_period(current_month_start, Date.current)
    current_affiliates = SubAgent.where('created_at >= ?', current_month_start).count
    current_leads = Lead.where('created_at >= ?', current_month_start).count
    current_renewals = get_renewals_count_for_period(current_month_start, Date.current)
    current_payouts = get_payouts_for_period(current_month_start, Date.current)
    current_sum_insured = get_sum_insured_for_period(current_month_start, Date.current)

    # Last month data
    last_customers = Customer.where(created_at: last_month_start..last_month_end).count
    last_policies = get_policies_count_for_period(last_month_start, last_month_end)
    last_premium = get_premium_for_period(last_month_start, last_month_end)
    last_affiliates = SubAgent.where(created_at: last_month_start..last_month_end).count
    last_leads = Lead.where(created_at: last_month_start..last_month_end).count
    last_renewals = get_renewals_count_for_period(last_month_start, last_month_end)
    last_payouts = get_payouts_for_period(last_month_start, last_month_end)
    last_sum_insured = get_sum_insured_for_period(last_month_start, last_month_end)

    # Calculate growth percentages
    @customer_growth = calculate_percentage_change(current_customers, last_customers)
    @policy_growth = calculate_percentage_change(current_policies, last_policies)
    @premium_growth = calculate_percentage_change(current_premium, last_premium)
    @affiliate_growth = calculate_percentage_change(current_affiliates, last_affiliates)
    @lead_growth = calculate_percentage_change(current_leads, last_leads)
    @renewal_growth = calculate_percentage_change(current_renewals, last_renewals)
    @payout_growth = calculate_percentage_change(current_payouts, last_payouts)
    @sum_insured_growth = calculate_percentage_change(current_sum_insured, last_sum_insured)

    # Additional metrics
    @conversion_rate = @total_leads > 0 ? ((@converted_leads.to_f / @total_leads) * 100).round(1) : 0
    @avg_policy_value = @total_policies > 0 ? (@total_premium_collected / @total_policies).round(0) : 0
    @customer_retention = calculate_customer_retention_rate
    @monthly_recurring_revenue = calculate_monthly_recurring_revenue
  end

  private

  def get_policies_count_for_period(start_date, end_date)
    health = HealthInsurance.where(created_at: start_date..end_date).count
    life = LifeInsurance.where(created_at: start_date..end_date).count
    motor = MotorInsurance.where(created_at: start_date..end_date).count rescue 0
    other = OtherInsurance.where(created_at: start_date..end_date).count rescue 0
    health + life + motor + other
  end

  def get_premium_for_period(start_date, end_date)
    health = HealthInsurance.where(created_at: start_date..end_date).sum(:total_premium) || 0
    life = LifeInsurance.where(created_at: start_date..end_date).sum(:total_premium) || 0
    motor = MotorInsurance.where(created_at: start_date..end_date).sum(:total_premium) rescue 0
    health + life + motor
  end

  def get_renewals_count_for_period(start_date, end_date)
    thirty_days_ahead = end_date + 30.days
    health = HealthInsurance.where(created_at: start_date..end_date)
                           .where('policy_end_date BETWEEN ? AND ?', end_date, thirty_days_ahead).count
    life = LifeInsurance.where(created_at: start_date..end_date)
                        .where('policy_end_date BETWEEN ? AND ?', end_date, thirty_days_ahead).count
    motor = MotorInsurance.where(created_at: start_date..end_date)
                          .where('policy_end_date BETWEEN ? AND ?', end_date, thirty_days_ahead).count rescue 0
    health + life + motor
  end

  def get_payouts_for_period(start_date, end_date)
    commission = CommissionPayout.where(created_at: start_date..end_date, status: 'pending').sum(:payout_amount) || 0
    distributor = DistributorPayout.where(created_at: start_date..end_date, status: 'pending').sum(:payout_amount) rescue 0
    commission + distributor
  end

  def get_sum_insured_for_period(start_date, end_date)
    health = HealthInsurance.where(created_at: start_date..end_date).sum(:sum_insured) || 0
    life = LifeInsurance.where(created_at: start_date..end_date).sum(:sum_insured) || 0
    motor = MotorInsurance.where(created_at: start_date..end_date).sum(:sum_insured) rescue 0
    health + life + motor
  end

  def calculate_percentage_change(current_value, previous_value)
    return 0 if previous_value == 0
    return 100 if previous_value == 0 && current_value > 0
    ((current_value.to_f - previous_value.to_f) / previous_value.to_f * 100).round(1)
  end

  def calculate_customer_retention_rate
    # Calculate retention rate for customers who joined 2+ months ago
    two_months_ago = 2.months.ago.beginning_of_month
    old_customers = Customer.where('created_at < ?', two_months_ago).count
    active_old_customers = Customer.where('created_at < ?', two_months_ago).where(status: true).count

    old_customers > 0 ? ((active_old_customers.to_f / old_customers.to_f) * 100).round(1) : 0
  end

  def calculate_monthly_recurring_revenue
    # Estimate based on average premium per month
    monthly_premium = @total_premium_collected / 12.0
    monthly_premium.round(0)
  end

  def calculate_age_distribution
    age_groups = {
      '18-25' => 0,
      '26-35' => 0,
      '36-45' => 0,
      '46-55' => 0,
      '56-65' => 0,
      '65+' => 0
    }

    Customer.where.not(birth_date: nil).find_each do |customer|
      age = ((Date.current - customer.birth_date) / 365.25).to_i
      case age
      when 18..25
        age_groups['18-25'] += 1
      when 26..35
        age_groups['26-35'] += 1
      when 36..45
        age_groups['36-45'] += 1
      when 46..55
        age_groups['46-55'] += 1
      when 56..65
        age_groups['56-65'] += 1
      else
        age_groups['65+'] += 1 if age > 65
      end
    end

    age_groups
  end

  def calculate_policy_status_distribution
    active_policies = HealthInsurance.where('policy_end_date > ?', Date.current).count +
                     LifeInsurance.where('policy_end_date > ?', Date.current).count +
                     MotorInsurance.where('policy_end_date > ?', Date.current).count

    expired_policies = HealthInsurance.where('policy_end_date < ?', Date.current).count +
                      LifeInsurance.where('policy_end_date < ?', Date.current).count +
                      MotorInsurance.where('policy_end_date < ?', Date.current).count

    expiring_soon = HealthInsurance.where('policy_end_date BETWEEN ? AND ?', Date.current, 30.days.from_now).count +
                   LifeInsurance.where('policy_end_date BETWEEN ? AND ?', Date.current, 30.days.from_now).count +
                   MotorInsurance.where('policy_end_date BETWEEN ? AND ?', Date.current, 30.days.from_now).count

    {
      'Active' => active_policies,
      'Expired' => expired_policies,
      'Expiring Soon' => expiring_soon
    }
  end

  def calculate_monthly_revenue_breakdown
    revenue_breakdown = {}
    6.times do |i|
      month_date = (Date.current - i.months).beginning_of_month
      month_name = month_date.strftime('%b')

      health_revenue = HealthInsurance.where(created_at: month_date..(month_date.end_of_month)).sum(:total_premium) || 0
      life_revenue = LifeInsurance.where(created_at: month_date..(month_date.end_of_month)).sum(:total_premium) || 0
      motor_revenue = MotorInsurance.where(created_at: month_date..(month_date.end_of_month)).sum(:total_premium) || 0

      revenue_breakdown[month_name] = {
        health: health_revenue,
        life: life_revenue,
        motor: motor_revenue,
        total: health_revenue + life_revenue + motor_revenue
      }
    end

    revenue_breakdown.to_a.reverse.to_h
  end
end
