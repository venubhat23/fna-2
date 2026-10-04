class DashboardController < ApplicationController
  skip_load_and_authorize_resource

  # See lib/local_ttl_cache.rb - Rails.cache is Solid Cache here (same remote Postgres
  # as the primary DB), so even a Rails.cache "hit" on the dashboard snapshots below
  # still paid a full network round trip. This in-process cache turns that into a
  # plain hash read on every request but the first each TTL window.
  DASHBOARD_LOCAL_CACHE = LocalTtlCache.new

  def index
    # Handle session validation requests
    if request.headers['X-Session-Validation'] == 'true'
      # Lightweight session validation - just return 200 OK if authenticated
      head :ok
      return
    end

    authorize! :read, :dashboard
    load_dashboard_lists
    load_ecommerce_dashboard_data
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

  def ecommerce
    authorize! :read, :dashboard
    load_ecommerce_dashboard_data
    render 'ecommerce_dashboard', layout: false
  end

  def dummy
    authorize! :read, :dashboard
    render 'dummy', layout: false
  end

  def modern
    authorize! :read, :dashboard
    load_ecommerce_dashboard_data
    render 'modern', layout: false
  end

  def stats
    authorize! :read, :dashboard
    load_ecommerce_dashboard_data

    # Get recent orders with customer info
    recent_orders = Booking.includes(:customer)
                          .recent
                          .limit(10)
                          .map do |booking|
      {
        id: booking.booking_number,
        customer: booking.customer&.display_name || 'Guest Customer',
        status: booking.status.capitalize,
        amount: booking.total_amount.to_i,
        date: booking.created_at.strftime('%Y-%m-%d')
      }
    end

    # Get top products
    top_products = Product.joins(:booking_items)
                         .joins('JOIN bookings ON booking_items.booking_id = bookings.id')
                         .where('bookings.status IN (?)', ['delivered', 'completed'])
                         .includes(:category)
                         .group('products.id, products.name')
                         .select('products.id, products.name, products.category_id,
                                 SUM(booking_items.quantity * booking_items.price) as revenue,
                                 SUM(booking_items.quantity) as sold')
                         .order('revenue DESC')
                         .limit(5)
                         .map do |product|
      category_name = product.category&.name || 'General'
      {
        id: product.id,
        name: product.name,
        category: category_name,
        revenue: product.revenue.to_i,
        sold: product.sold.to_i
      }
    end

    # Get order status distribution — one grouped query replaces 4 separate counts
    booking_status_breakdown = Booking.group(:status).count
    order_status_data = {
      'Completed' => %w[delivered completed].sum { |s| booking_status_breakdown[s] || 0 },
      'Processing' => %w[confirmed processing packed].sum { |s| booking_status_breakdown[s] || 0 },
      'Shipped' => %w[shipped out_for_delivery].sum { |s| booking_status_breakdown[s] || 0 },
      'Cancelled' => booking_status_breakdown['cancelled'] || 0
    }

    # Generate sample activities
    activities = [
      {
        id: 1,
        type: 'order',
        title: 'New Order',
        description: "Order #{recent_orders.first&.dig(:id) || 'BK001'} placed",
        time: 2.minutes.ago
      },
      {
        id: 2,
        type: 'customer',
        title: 'New Customer',
        description: 'Customer registration completed',
        time: 5.minutes.ago
      },
      {
        id: 3,
        type: 'payment',
        title: 'Payment Received',
        description: "Payment of ₹#{recent_orders.first&.dig(:amount) || 2500} received",
        time: 8.minutes.ago
      }
    ]

    render json: {
      # E-commerce metrics
      total_revenue: @total_revenue,
      total_bookings: @total_bookings,
      total_customers: @total_customers,
      total_products: @total_products,
      active_products: @active_products,

      # Order metrics
      pending_bookings: @pending_bookings,
      completed_bookings: @completed_bookings,
      cancelled_bookings: @cancelled_bookings,

      # Revenue metrics
      today_revenue: @today_revenue,
      month_revenue: @month_revenue,
      avg_order_value: @avg_order_value,

      # Growth metrics
      revenue_growth: @revenue_growth,
      order_growth: @order_growth,
      customer_acquisition_growth: @customer_acquisition_growth,

      # Charts data
      monthly_revenue_trend: @monthly_revenue_trend,
      category_performance: @category_performance,
      order_status_distribution: order_status_data,
      sales_trend: @sales_trend,

      # Recent data
      recent_orders: recent_orders,
      top_products: top_products,
      activities: activities,

      # Timestamp
      last_updated: Time.current.strftime('%Y-%m-%d %H:%M:%S'),
      cache_key: "dashboard_#{Time.current.to_i}"
    }
  end

  private

  # Cached wrapper, same pattern as load_ecommerce_dashboard_data above: avoids repeating
  # this method's DB round trips (including a remote-Postgres query) on every dashboard hit.
  DASHBOARD_INSURANCE_CACHE_IVARS = %i[
    @total_customers @active_customers @inactive_customers
    @total_affiliates @total_sub_agents
    @total_policies @total_premium_collected @total_sum_insured
    @total_leads @converted_leads @pending_leads @lead_conversion_percentage
    @renewal_due_count @expired_policies_count
    @pending_payouts @paid_payouts @total_payouts
    @policy_type_distribution
    @customer_location @age_distribution @policy_status_distribution @monthly_revenue_breakdown @premium_by_type
    @client_requests_count @claims_processing @docs_pending @commissions_due @new_leads @support_tickets
    @customer_growth @policy_growth @premium_growth @affiliate_growth @lead_growth
    @renewal_growth @payout_growth @sum_insured_growth
    @conversion_rate @avg_policy_value @customer_retention @monthly_recurring_revenue
  ].freeze

  def load_dashboard_data
    # Load actual data from database instead of static zeros
    load_ecommerce_dashboard_data

    snapshot = DASHBOARD_LOCAL_CACHE.fetch('dashboard:insurance_data', 5.minutes) do
      compute_dashboard_insurance_data
      DASHBOARD_INSURANCE_CACHE_IVARS.each_with_object({}) do |ivar, hash|
        hash[ivar] = instance_variable_get(ivar)
      end
    end
    snapshot.each { |ivar, value| instance_variable_set(ivar, value) }
  end

  def compute_dashboard_insurance_data
    # Additional insurance-specific metrics that might be needed
    begin
      # Basic counts
      @total_customers = Customer.count
      @active_customers = Customer.where(status: true).count rescue @total_customers
      @inactive_customers = @total_customers - @active_customers

      # Insurance-specific data (if available)
      @total_affiliates = SubAgent.count rescue 0
      @total_sub_agents = SubAgent.count rescue 0

      # Get policy counts using optimized helper methods
      policy_counts = get_optimized_policy_counts
      @total_policies = policy_counts[:total_count]

      # Get premium data
      premium_data = get_optimized_premium_data
      @total_premium_collected = premium_data[:total_premium]
      @total_sum_insured = premium_data[:total_sum_insured]

      # Lead data (if available)
      @total_leads = Lead.count rescue 0
      @converted_leads = Lead.where(status: 'converted').count rescue 0
      @pending_leads = Lead.where(status: 'pending').count rescue 0
      @lead_conversion_percentage = @total_leads > 0 ? ((@converted_leads.to_f / @total_leads) * 100).round(1) : 0

      # Renewal and expiry counts
      thirty_days_from_now = 30.days.from_now.to_date
      @renewal_due_count = get_renewal_due_count(thirty_days_from_now)
      @expired_policies_count = get_expired_policies_count

      # Payout data
      payout_data = get_optimized_payout_data
      @pending_payouts = payout_data[:pending_amount]
      @paid_payouts = payout_data[:paid_amount]
      @total_payouts = payout_data[:total_amount]

      # Policy type distribution
      @policy_type_distribution = {
        'Health Insurance' => { count: policy_counts[:health_count], percentage: policy_counts[:total_count] > 0 ? (policy_counts[:health_count].to_f / policy_counts[:total_count] * 100).round(1) : 0 },
        'Life Insurance' => { count: policy_counts[:life_count], percentage: policy_counts[:total_count] > 0 ? (policy_counts[:life_count].to_f / policy_counts[:total_count] * 100).round(1) : 0 },
        'Motor Insurance' => { count: policy_counts[:motor_count], percentage: policy_counts[:total_count] > 0 ? (policy_counts[:motor_count].to_f / policy_counts[:total_count] * 100).round(1) : 0 },
        'Other Insurance' => { count: policy_counts[:other_count], percentage: policy_counts[:total_count] > 0 ? (policy_counts[:other_count].to_f / policy_counts[:total_count] * 100).round(1) : 0 }
      }

      # Chart and analysis data
      @customer_location = calculate_customer_locations
      @age_distribution = calculate_age_distribution
      @policy_status_distribution = calculate_policy_status_distribution
      @monthly_revenue_breakdown = calculate_monthly_revenue_breakdown
      @premium_by_type = {
        'Health Insurance' => HealthInsurance.sum(:total_premium) || 0,
        'Life Insurance' => LifeInsurance.sum(:total_premium) || 0,
        'Motor Insurance' => (MotorInsurance.sum(:total_premium) rescue 0)
      }

      # Growth metrics
      calculate_growth_metrics

      # Additional metrics
      @client_requests_count = 0 # Add actual model query if available
      @claims_processing = 0 # Add actual model query if available
      @docs_pending = 0 # Add actual model query if available
      @commissions_due = @pending_payouts
      @new_leads = Lead.where('created_at >= ?', Date.current.beginning_of_month).count rescue 0
      @support_tickets = 0 # Add actual model query if available

    rescue => e
      # Fallback to zero values if there are any errors
      Rails.logger.error "Dashboard data loading error: #{e.message}"

      @total_customers ||= 0
      @active_customers ||= 0
      @inactive_customers ||= 0
      @total_affiliates ||= 0
      @total_sub_agents ||= 0
      @total_policies ||= 0
      @total_premium_collected ||= 0
      @total_sum_insured ||= 0
      @total_leads ||= 0
      @converted_leads ||= 0
      @pending_leads ||= 0
      @lead_conversion_percentage ||= 0
      @renewal_due_count ||= 0
      @expired_policies_count ||= 0
      @pending_payouts ||= 0
      @paid_payouts ||= 0
      @total_payouts ||= 0
      @policy_type_distribution ||= {
        'Health Insurance' => { count: 0, percentage: 0 },
        'Life Insurance' => { count: 0, percentage: 0 },
        'Motor Insurance' => { count: 0, percentage: 0 },
        'Other Insurance' => { count: 0, percentage: 0 }
      }
      @customer_location ||= {}
      @age_distribution ||= {}
      @policy_status_distribution ||= {}
      @monthly_revenue_breakdown ||= {}
      @premium_by_type ||= { 'Health Insurance' => 0, 'Life Insurance' => 0, 'Motor Insurance' => 0 }
    end
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

    # Only the birth_date column is needed - plucking it avoids instantiating every Customer.
    Customer.where.not(birth_date: nil).pluck(:birth_date).each do |birth_date|
      age = ((Date.current - birth_date) / 365.25).to_i
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
    # Hoisted out of the loop below: these categories don't change per-month, so looking
    # them up once instead of on every one of the 6 iterations saves ~4 queries x 5 iterations.
    electronics_category = Category.find_by(name: 'Electronics')
    clothing_category = Category.find_by(name: 'Clothing')
    home_category = Category.find_by(name: ['Home & Garden', 'Home', 'Garden'].find { |name| Category.find_by(name: name) })

    revenue_breakdown = {}
    6.times do |i|
      month_date = (Date.current - i.months).beginning_of_month
      month_name = month_date.strftime('%b')

      electronics_revenue = 0
      clothing_revenue = 0
      home_revenue = 0

      if electronics_category
        electronics_revenue = BookingItem.joins(:booking, :product)
                                        .where(bookings: { created_at: month_date..(month_date.end_of_month) })
                                        .where(products: { category: electronics_category })
                                        .sum('booking_items.quantity * booking_items.price') || 0
      end

      if clothing_category
        clothing_revenue = BookingItem.joins(:booking, :product)
                                     .where(bookings: { created_at: month_date..(month_date.end_of_month) })
                                     .where(products: { category: clothing_category })
                                     .sum('booking_items.quantity * booking_items.price') || 0
      end

      if home_category
        home_revenue = BookingItem.joins(:booking, :product)
                                 .where(bookings: { created_at: month_date..(month_date.end_of_month) })
                                 .where(products: { category: home_category })
                                 .sum('booking_items.quantity * booking_items.price') || 0
      end

      # Fallback: distribute total revenue across categories if specific categories don't exist
      total_monthly_revenue = Booking.where(created_at: month_date..(month_date.end_of_month)).sum(:total_amount) || 0

      if electronics_revenue == 0 && clothing_revenue == 0 && home_revenue == 0 && total_monthly_revenue > 0
        # Distribute revenue proportionally if no category-specific data
        electronics_revenue = (total_monthly_revenue * 0.4).round(0)  # 40%
        clothing_revenue = (total_monthly_revenue * 0.35).round(0)    # 35%
        home_revenue = (total_monthly_revenue * 0.25).round(0)        # 25%
      end

      revenue_breakdown[month_name] = {
        electronics: electronics_revenue,
        clothing: clothing_revenue,
        home: home_revenue,
        total: electronics_revenue + clothing_revenue + home_revenue
      }
    end

    revenue_breakdown.to_a.reverse.to_h
  end

  # Cached wrapper around the actual (query-heavy, ~40-query) data load. The dashboard is
  # viewed repeatedly (page refreshes, multiple admins, polling) and the underlying numbers
  # don't need to be instantaneous, so a cache turns dozens of round trips into zero on
  # every hit but the first each cache period. Each query here is a full network round trip
  # to the remote Postgres instance (~150-500ms/query - see logs from 2026-08-01).
  #
  # Two layers: DASHBOARD_LOCAL_CACHE is per-worker-process (zero-cost hit, no network hop),
  # but on a multi-worker deploy each worker independently recomputes on its own first hit
  # and again every TTL — so a Rails.cache (Solid Cache) layer sits underneath it, shared
  # across all workers. A miss on the local layer usually still hits Rails.cache (one round
  # trip to fetch the cached blob) instead of falling all the way through to all ~40 queries.
  # TTL is 2 minutes on both layers (staleness tolerance for this dashboard).
  DASHBOARD_ECOMMERCE_CACHE_IVARS = %i[
    @total_products @active_products @draft_products @total_categories @active_categories
    @total_bookings @pending_bookings @completed_bookings @cancelled_bookings
    @total_orders @pending_orders @shipped_orders @delivered_orders @cancelled_orders
    @total_revenue @today_revenue @month_revenue @avg_order_value
    @total_vendors @active_vendors @total_purchases @pending_purchases @total_purchase_value @pending_payments
    @total_stores @active_stores
    @total_stock_value @low_stock_products @out_of_stock_products @top_categories
    @total_customers @new_customers_this_month
    @sales_trend @category_performance @order_status_distribution @top_selling_products
    @monthly_revenue_trend @payment_method_distribution @delivery_performance
    @revenue_growth @order_growth @customer_acquisition_growth @conversion_rate @inventory_turnover
    @customer_location
  ].freeze

  # The small lists on the index page. Started with load_async before the stats load so
  # their round trips to the remote DB overlap instead of running back to back, and
  # eager_load joins each list's association into its main query.
  def load_dashboard_lists
    @dashboard_recent_bookings = Booking.eager_load(:customer).order(created_at: :desc).limit(5).load_async
    @dashboard_top_customers = Customer.order(created_at: :desc).limit(5).load_async
    @dashboard_low_stock_list = Product.eager_load(:category).where('products.stock <= 5 AND products.stock > 0').limit(5).load_async
  end

  def load_ecommerce_dashboard_data
    snapshot = DASHBOARD_LOCAL_CACHE.fetch('dashboard:ecommerce_data', 2.minutes) do
      Rails.cache.fetch('dashboard:ecommerce_data', expires_in: 2.minutes) do
        compute_ecommerce_dashboard_data
        DASHBOARD_ECOMMERCE_CACHE_IVARS.each_with_object({}) do |ivar, hash|
          hash[ivar] = instance_variable_get(ivar)
        end
      end
    end
    snapshot.each { |ivar, value| instance_variable_set(ivar, value) }
  end

  # On a cache miss this used to run ~40 queries back to back (one remote round trip
  # each). Now the grouped queries are started with async_* so they run on the async
  # executor while every scalar COUNT/SUM goes out together in one BatchAggregate query.
  # Each value is computed from the exact same relation as before.
  def compute_ecommerce_dashboard_data
    product_status_counts_promise = Product.group(:status).async_count
    booking_status_counts_promise = Booking.group(:status).async_count
    vendor_status_counts_promise = Vendor.group(:status).async_count
    vendor_purchase_status_counts_promise = VendorPurchase.group(:status).async_count
    store_status_counts_promise = Store.group(:status).async_count
    top_categories_promise = start_top_categories
    sales_trend_promise = start_sales_trend
    category_performance_promise = start_category_performance
    top_selling_products_promise = start_top_selling_products

    today = Date.current.beginning_of_day..Date.current.end_of_day
    this_month = Date.current.beginning_of_month..Date.current.end_of_month
    current_month_start = Date.current.beginning_of_month
    last_month = 1.month.ago.beginning_of_month..1.month.ago.end_of_month
    # NOTE: kept as one range per month with `month_date.end_of_month` (a Date), which
    # against the datetime column compiles to `BETWEEN month_start AND midnight of the
    # last day` - a pre-existing quirk that excludes most of the last day. Bucketing in
    # Ruby would change the displayed totals, so the exact per-month ranges stay.
    revenue_months = (0...6).map { |i| (Date.current - i.months).beginning_of_month }

    # NOTE: Order#status and Booking#payment_method are integer-backed enums stored in
    # string columns, so `.group(...).count` would return raw values - `.where(x: 'label')`
    # applies the enum's label translation, hence one scalar per label.
    scalars = {
      total_categories: [Category.all, :count],
      active_categories: [Category.where(status: true), :count],
      total_orders: [Order.all, :count],
      pending_orders: [Order.where(status: 'pending'), :count],
      shipped_orders: [Order.where(status: 'shipped'), :count],
      delivered_orders: [Order.where(status: 'delivered'), :count],
      cancelled_orders: [Order.where(status: 'cancelled'), :count],
      total_revenue: [Booking.all, :sum, :total_amount],
      today_revenue: [Booking.where(created_at: today), :sum, :total_amount],
      month_revenue: [Booking.where(created_at: this_month), :sum, :total_amount],
      total_purchase_value: [VendorPurchase.all, :sum, :total_amount],
      total_stock_value: [Product.all, :sum, 'price * stock'],
      low_stock_products: [Product.where('stock <= 5 AND stock > 0'), :count],
      out_of_stock_products: [Product.where(stock: 0), :count],
      total_customers: [Customer.all, :count],
      new_customers_this_month: [Customer.where(created_at: this_month), :count],
      pay_cash: [Booking.where(payment_method: 'cash'), :count],
      pay_card: [Booking.where(payment_method: 'card'), :count],
      pay_upi: [Booking.where(payment_method: 'upi'), :count],
      pay_online: [Booking.where(payment_method: 'online'), :count],
      delivered_on_time: [Order.where('delivered_at <= created_at + INTERVAL \'3 days\''), :count],
      total_delivered: [Order.where.not(delivered_at: nil), :count],
      current_revenue: [Booking.where('created_at >= ?', current_month_start), :sum, :total_amount],
      current_orders: [Booking.where('created_at >= ?', current_month_start), :count],
      current_customers: [Customer.where('created_at >= ?', current_month_start), :count],
      last_revenue: [Booking.where(created_at: last_month), :sum, :total_amount],
      last_orders: [Booking.where(created_at: last_month), :count],
      last_customers: [Customer.where(created_at: last_month), :count]
    }
    revenue_months.each_with_index do |month_date, i|
      scalars[:"month_revenue_#{i}"] = [Booking.where(created_at: month_date..month_date.end_of_month), :sum, :total_amount]
    end
    agg = BatchAggregate.call(**scalars)

    # E-commerce specific metrics
    product_status_counts = product_status_counts_promise.value
    @total_products = product_status_counts.values.sum
    @active_products = product_status_counts['active'] || 0
    @draft_products = product_status_counts['draft'] || 0
    @total_categories = agg[:total_categories]
    @active_categories = agg[:active_categories]

    # Booking metrics
    booking_status_counts = booking_status_counts_promise.value
    @total_bookings = booking_status_counts.values.sum
    @pending_bookings = booking_status_counts['pending'] || 0
    @completed_bookings = booking_status_counts['completed'] || 0
    @cancelled_bookings = booking_status_counts['cancelled'] || 0

    # Order metrics
    @total_orders = agg[:total_orders]
    @pending_orders = agg[:pending_orders]
    @shipped_orders = agg[:shipped_orders]
    @delivered_orders = agg[:delivered_orders]
    @cancelled_orders = agg[:cancelled_orders]

    # Revenue metrics
    @total_revenue = agg[:total_revenue]
    @today_revenue = agg[:today_revenue]
    @month_revenue = agg[:month_revenue]
    @avg_order_value = @total_bookings > 0 ? (@total_revenue / @total_bookings).round(2) : 0

    # Vendor metrics
    vendor_status_counts = vendor_status_counts_promise.value rescue {}
    @total_vendors = vendor_status_counts.values.sum
    @active_vendors = vendor_status_counts[true] || 0

    vendor_purchase_status_counts = vendor_purchase_status_counts_promise.value rescue {}
    @total_purchases = vendor_purchase_status_counts.values.sum
    @pending_purchases = vendor_purchase_status_counts['pending'] || 0
    @total_purchase_value = agg[:total_purchase_value]
    # VendorPayment has neither a `status` nor an `amount` column, so this always raised
    # and fell through to 0 anyway — skip the guaranteed-failing round trip.
    @pending_payments = 0

    # Store metrics
    store_status_counts = store_status_counts_promise.value rescue {}
    @total_stores = store_status_counts.values.sum
    @active_stores = store_status_counts[true] || 0

    # Inventory metrics
    @total_stock_value = agg[:total_stock_value]
    @low_stock_products = agg[:low_stock_products]
    @out_of_stock_products = agg[:out_of_stock_products]
    @top_categories = finish_top_categories(top_categories_promise)

    # Customer metrics (using existing customers)
    @total_customers = agg[:total_customers]
    @new_customers_this_month = agg[:new_customers_this_month]

    # Chart data
    @sales_trend = finish_sales_trend(sales_trend_promise)
    @category_performance = finish_category_performance(category_performance_promise)
    @order_status_distribution = calculate_order_status_distribution
    @top_selling_products = top_selling_products_promise.value
    @monthly_revenue_trend = revenue_months.each_with_index.to_h { |month_date, i| [month_date.strftime('%b %Y'), agg[:"month_revenue_#{i}"]] }.to_a.reverse.to_h
    @payment_method_distribution = {
      'Cash' => agg[:pay_cash],
      'Card' => agg[:pay_card],
      'UPI' => agg[:pay_upi],
      'Online' => agg[:pay_online]
    }
    total_delivered = agg[:total_delivered]
    @delivery_performance = {
      on_time_percentage: total_delivered > 0 ? ((agg[:delivered_on_time].to_f / total_delivered) * 100).round(1) : 0,
      total_delivered: total_delivered,
      avg_delivery_days: total_delivered > 0 ? 3.2 : 0  # Sample data
    }

    # Growth metrics
    @revenue_growth = calculate_percentage_change(agg[:current_revenue], agg[:last_revenue])
    @order_growth = calculate_percentage_change(agg[:current_orders], agg[:last_orders])
    @customer_acquisition_growth = calculate_percentage_change(agg[:current_customers], agg[:last_customers])
    @inventory_turnover = @total_stock_value > 0 ? (@total_revenue / @total_stock_value).round(2) : 0

    # Additional ecommerce metrics
    @conversion_rate = @total_customers > 0 ? ((@total_bookings.to_f / @total_customers) * 100).round(2) : 0

    # Customer location data for ecommerce
    @customer_location = calculate_customer_locations
  end

  private

  # Top 5 categories by product count
  def start_top_categories
    Category.joins(:products)
            .group('categories.name')
            .order('COUNT(products.id) DESC')
            .limit(5)
            .async_count
  end

  def finish_top_categories(promise)
    promise.value
  rescue
    # Return sample data if there's an error
    Category.limit(5).pluck(:name).map { |name| [name, rand(5..20)] }.to_h
  end

  # Last 7 days sales trend — one query (created_at is indexed) instead of 7
  def start_sales_trend
    start_date = 6.days.ago.to_date
    Booking.where(created_at: start_date.beginning_of_day..Date.current.end_of_day)
           .async_pluck(:created_at, :total_amount)
  end

  def finish_sales_trend(promise)
    start_date = 6.days.ago.to_date
    trend = {}
    7.times { |i| trend[(start_date + i.days).strftime('%a')] = 0 }

    promise.value.each do |created_at, amount|
      key = created_at.to_date.strftime('%a')
      trend[key] += (amount || 0) if trend.key?(key)
    end

    trend
  end

  # Revenue by category in a single grouped query instead of per-product lookups
  def start_category_performance
    BookingItem.joins(:booking, product: :category)
               .group('categories.name')
               .async_sum('booking_items.quantity * booking_items.price')
  end

  def finish_category_performance(promise)
    promise.value
           .select { |_name, revenue| revenue > 0 }
           .sort_by { |_name, revenue| -revenue }
           .to_h
  end

  def calculate_order_status_distribution
    {
      'Pending' => @pending_orders,
      'Shipped' => @shipped_orders,
      'Delivered' => @delivered_orders,
      'Cancelled' => @cancelled_orders
    }
  end

  # Top 5 products by quantity sold
  def start_top_selling_products
    BookingItem.joins(:product, :booking)
               .group('products.name')
               .order('SUM(booking_items.quantity) DESC')
               .limit(5)
               .async_sum(:quantity)
  end

  def calculate_customer_locations
    # The customers table has no state/city column, so this always raised and fell
    # through to {} anyway — skip the guaranteed-failing round trip.
    {}
  end
end
