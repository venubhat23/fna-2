class Admin::ReportsController < Admin::ApplicationController

  # Explicitly skip CanCan for this controller
  skip_authorization_check if respond_to?(:skip_authorization_check)
  skip_load_and_authorize_resource if respond_to?(:skip_load_and_authorize_resource)

  # GET /admin/reports/commission
  def commission
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    # Commission calculations would go here
    # This is a placeholder implementation
    @total_commission = Policy.where(created_at: start_date..Time.current).sum(:total_premium) * 0.1 rescue 0
    @commission_by_agent = User.where(user_type: ['agent', 'sub_agent'])
                               .joins(:policies)
                               .where(policies: { created_at: start_date..Time.current })
                               .group('users.first_name', 'users.last_name')
                               .sum('policies.total_premium * 0.1') rescue {}
  end

  # GET /admin/reports/expired_insurance
  def expired_insurance
    @expired_health_insurances = HealthInsurance.expired.includes(:customer).order(:policy_end_date)
    @expired_life_insurances = LifeInsurance.expired.includes(:customer).order(:policy_end_date)
    @expired_motor_insurances = MotorInsurance.expired.includes(policy: :customer).order(:policy_end_date)
    @expired_other_insurances = OtherInsurance.expired.includes(policy: :customer).order(:policy_end_date)

    @stats = {
      total_expired: @expired_health_insurances.count + @expired_life_insurances.count +
                    @expired_motor_insurances.count + @expired_other_insurances.count,
      health_expired: @expired_health_insurances.count,
      life_expired: @expired_life_insurances.count,
      motor_expired: @expired_motor_insurances.count,
      other_expired: @expired_other_insurances.count
    }
  rescue => e
    Rails.logger.error "Error in expired_insurance: #{e.message}"
    @expired_health_insurances = HealthInsurance.none
    @expired_life_insurances = LifeInsurance.none
    @expired_motor_insurances = MotorInsurance.none
    @expired_other_insurances = OtherInsurance.none
    @stats = {
      total_expired: 0,
      health_expired: 0,
      life_expired: 0,
      motor_expired: 0,
      other_expired: 0
    }
  end

  # GET /admin/reports/payment_due
  def payment_due
    # Logic for payment due reports
    @payment_due_policies = Policy.active
                                  .where('end_date > ? AND end_date <= ?', Date.current, 30.days.from_now)
                                  .includes(:customer)
                                  .order(:end_date) rescue []
  end

  # GET /admin/reports/upcoming_renewal
  def upcoming_renewal
    # Define renewal period (next 60 days)
    start_date = Date.current
    end_date = 60.days.from_now

    @renewal_health_insurances = HealthInsurance.where(policy_end_date: start_date..end_date)
                                               .includes(:customer)
                                               .order(:policy_end_date)

    @renewal_life_insurances = LifeInsurance.where(policy_end_date: start_date..end_date)
                                           .includes(:customer)
                                           .order(:policy_end_date)

    @renewal_motor_insurances = MotorInsurance.where(policy_end_date: start_date..end_date)
                                             .includes(policy: :customer)
                                             .order(:policy_end_date)

    @renewal_other_insurances = OtherInsurance.where(policy_end_date: start_date..end_date)
                                             .includes(policy: :customer)
                                             .order(:policy_end_date)

    @stats = {
      total_renewals: @renewal_health_insurances.count + @renewal_life_insurances.count +
                     @renewal_motor_insurances.count + @renewal_other_insurances.count,
      health_renewals: @renewal_health_insurances.count,
      life_renewals: @renewal_life_insurances.count,
      motor_renewals: @renewal_motor_insurances.count,
      other_renewals: @renewal_other_insurances.count
    }
  rescue => e
    Rails.logger.error "Error in upcoming_renewal: #{e.message}"
    @renewal_health_insurances = HealthInsurance.none
    @renewal_life_insurances = LifeInsurance.none
    @renewal_motor_insurances = MotorInsurance.none
    @renewal_other_insurances = OtherInsurance.none
    @stats = {
      total_renewals: 0,
      health_renewals: 0,
      life_renewals: 0,
      motor_renewals: 0,
      other_renewals: 0
    }
  end

  # GET /admin/reports/upcoming_payment
  def upcoming_payment
    @upcoming_payments = Policy.active
                               .where('end_date BETWEEN ? AND ?', Date.current, 30.days.from_now)
                               .includes(:customer)
                               .order(:end_date) rescue []
  end

  # GET /admin/reports/leads
  def leads
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    @leads_data = {
      total_leads: Lead.where(created_date: start_date..Time.current).count,
      conversion_rate: 0
    }

    if Lead.column_names.include?('current_stage')
      @leads_by_stage = Lead.where(created_date: start_date..Time.current)
                           .group(:current_stage)
                           .count
    else
      @leads_by_stage = {}
    end
  rescue
    @leads_data = { total_leads: 0, conversion_rate: 0 }
    @leads_by_stage = {}
  end

  # GET /admin/reports/sessions
  def sessions
    @date_range = params[:date_range] || 'today'

    # Calculate date range
    case @date_range
    when 'today'
      start_date = Date.current.beginning_of_day
      end_date = Date.current.end_of_day
    when '7_days'
      start_date = 7.days.ago.beginning_of_day
      end_date = Date.current.end_of_day
    when '30_days'
      start_date = 30.days.ago.beginning_of_day
      end_date = Date.current.end_of_day
    when '3_months'
      start_date = 3.months.ago.beginning_of_day
      end_date = Date.current.end_of_day
    else
      start_date = Date.current.beginning_of_day
      end_date = Date.current.end_of_day
    end

    # Session analytics
    @active_users = User.where(status: true).count
    @total_sessions = User.where(created_at: start_date..end_date).count
    @avg_session_time = "24m" # Placeholder for actual session tracking
    @failed_logins = 0 # Placeholder for failed login tracking

    # Sample recent sessions data
    @recent_sessions = User.where(status: true)
                          .limit(20)
                          .order(created_at: :desc)
                          .map.with_index do |user, index|
      {
        id: user.id,
        user_id: user.id,
        user_name: "#{user.first_name} #{user.last_name}".strip,
        email: user.email,
        user_type: user.user_type || 'user',
        login_time: user.created_at + rand(0..72).hours,
        last_activity: case rand(5)
                      when 0 then "Just now"
                      when 1 then "#{rand(1..10)} minutes ago"
                      when 2 then "#{rand(1..2)} hours ago"
                      else "#{rand(1..5)} hours ago"
                      end,
        duration: "#{rand(5..120)}m",
        ip_address: "192.168.1.#{rand(100..200)}",
        status: rand(10) < 7 ? 'active' : 'inactive'
      }
    end
  end

  # GET /admin/reports/products
  def products
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    if defined?(Product)
      @total_products = Product.count
      @active_products = Product.where(status: 'active').count rescue Product.count
      @out_of_stock = Product.where('stock <= ?', 0).count rescue 0
      @low_stock = Product.where('stock > 0 AND stock <= ?', 10).count rescue 0

      @top_products = Product.joins(:order_items)
                             .where(order_items: { created_at: start_date..Time.current })
                             .group('products.id', 'products.name')
                             .order('COUNT(order_items.id) DESC')
                             .limit(10)
                             .pluck('products.name', 'COUNT(order_items.id)') rescue []
    else
      @total_products = 0
      @active_products = 0
      @out_of_stock = 0
      @low_stock = 0
      @top_products = []
    end
  end

  # GET /admin/reports/customers
  def customers
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    @total_customers = Customer.count
    @new_customers = Customer.where(created_at: start_date..Time.current).count
    @active_customers = Customer.joins(:health_insurances)
                               .where(health_insurances: { created_at: start_date..Time.current })
                               .distinct.count rescue 0

    @customer_growth = []
    (0..6).each do |i|
      date = (6-i).days.ago.to_date
      count = Customer.where('DATE(created_at) = ?', date).count
      @customer_growth << { date: date.strftime('%b %d'), count: count }
    end
  end

  # GET /admin/reports/revenue
  def revenue
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    if defined?(Order)
      @total_revenue = Order.where(created_at: start_date..Time.current).sum(:total_amount)
      @total_orders = Order.where(created_at: start_date..Time.current).count
      @average_order_value = @total_orders > 0 ? (@total_revenue / @total_orders).round(2) : 0

      @revenue_by_day = []
      (0..6).each do |i|
        date = (6-i).days.ago.to_date
        revenue = Order.where('DATE(created_at) = ?', date).sum(:total_amount)
        @revenue_by_day << { date: date.strftime('%b %d'), revenue: revenue }
      end
    elsif defined?(Booking)
      @total_revenue = Booking.where(created_at: start_date..Time.current).sum(:total_amount)
      @total_orders = Booking.where(created_at: start_date..Time.current).count
      @average_order_value = @total_orders > 0 ? (@total_revenue / @total_orders).round(2) : 0

      @revenue_by_day = []
      (0..6).each do |i|
        date = (6-i).days.ago.to_date
        revenue = Booking.where('DATE(created_at) = ?', date).sum(:total_amount)
        @revenue_by_day << { date: date.strftime('%b %d'), revenue: revenue }
      end
    else
      @total_revenue = 0
      @total_orders = 0
      @average_order_value = 0
      @revenue_by_day = []
    end
  end

  # GET /admin/reports/inventory
  def inventory
    if defined?(Product)
      @total_products = Product.count
      @total_stock_value = Product.sum('stock * price') rescue 0
      @out_of_stock = Product.where('stock <= ?', 0).count rescue 0
      @low_stock = Product.where('stock > 0 AND stock <= ?', 10).count rescue 0

      @low_stock_products = Product.where('stock > 0 AND stock <= ?', 10)
                                   .order(:stock)
                                   .limit(20) rescue []

      @out_of_stock_products = Product.where('stock <= ?', 0)
                                      .order(:updated_at)
                                      .limit(20) rescue []

      @categories_stock = Category.joins(:products)
                                  .group('categories.name')
                                  .sum('products.stock') rescue {}
    else
      @total_products = 0
      @total_stock_value = 0
      @out_of_stock = 0
      @low_stock = 0
      @low_stock_products = []
      @out_of_stock_products = []
      @categories_stock = {}
    end
  end

  # GET /admin/reports/orders
  def orders
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    if defined?(Order)
      @total_orders = Order.where(created_at: start_date..Time.current).count
      @pending_orders = Order.where(created_at: start_date..Time.current, status: 'pending').count rescue 0
      @processing_orders = Order.where(created_at: start_date..Time.current, status: 'processing').count rescue 0
      @completed_orders = Order.where(created_at: start_date..Time.current, status: ['completed', 'delivered']).count rescue 0
      @cancelled_orders = Order.where(created_at: start_date..Time.current, status: 'cancelled').count rescue 0

      @recent_orders = Order.where(created_at: start_date..Time.current)
                           .includes(:customer)
                           .order(created_at: :desc)
                           .limit(20) rescue []

      @orders_by_status = Order.where(created_at: start_date..Time.current)
                               .group(:status)
                               .count rescue {}
    elsif defined?(Booking)
      @total_orders = Booking.where(created_at: start_date..Time.current).count
      @pending_orders = Booking.where(created_at: start_date..Time.current, status: 'pending').count rescue 0
      @processing_orders = Booking.where(created_at: start_date..Time.current, status: 'processing').count rescue 0
      @completed_orders = Booking.where(created_at: start_date..Time.current, status: ['completed', 'confirmed']).count rescue 0
      @cancelled_orders = Booking.where(created_at: start_date..Time.current, status: 'cancelled').count rescue 0

      @recent_orders = Booking.where(created_at: start_date..Time.current)
                             .includes(:customer)
                             .order(created_at: :desc)
                             .limit(20) rescue []

      @orders_by_status = Booking.where(created_at: start_date..Time.current)
                                .group(:status)
                                .count rescue {}
    else
      @total_orders = 0
      @pending_orders = 0
      @processing_orders = 0
      @completed_orders = 0
      @cancelled_orders = 0
      @recent_orders = []
      @orders_by_status = {}
    end
  end

  # GET /admin/reports/financial
  def financial
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    # Revenue calculations
    if defined?(Order)
      @total_revenue = Order.where(created_at: start_date..Time.current).sum(:total_amount)
      @total_tax = Order.where(created_at: start_date..Time.current).sum(:tax_amount)
      @total_discount = Order.where(created_at: start_date..Time.current).sum(:discount_amount)
      @net_revenue = @total_revenue - @total_tax - @total_discount
    elsif defined?(Booking)
      @total_revenue = Booking.where(created_at: start_date..Time.current).sum(:total_amount)
      @total_tax = Booking.where(created_at: start_date..Time.current).sum(:tax_amount)
      @total_discount = Booking.where(created_at: start_date..Time.current).sum(:discount_amount)
      @net_revenue = @total_revenue - @total_tax - @total_discount
    else
      @total_revenue = 0
      @total_tax = 0
      @total_discount = 0
      @net_revenue = 0
    end

    # Commission calculations
    @total_commissions = CommissionPayout.where(created_at: start_date..Time.current).sum(:payout_amount) rescue 0
    @pending_commissions = CommissionPayout.where(created_at: start_date..Time.current, status: 'pending').sum(:payout_amount) rescue 0
    @paid_commissions = CommissionPayout.where(created_at: start_date..Time.current, status: 'paid').sum(:payout_amount) rescue 0

    # Insurance premium calculations
    @health_premiums = HealthInsurance.where(created_at: start_date..Time.current).sum(:total_premium) rescue 0
    @life_premiums = LifeInsurance.where(created_at: start_date..Time.current).sum(:total_premium) rescue 0
    @motor_premiums = MotorInsurance.where(created_at: start_date..Time.current).sum(:total_premium) rescue 0
    @total_premiums = @health_premiums + @life_premiums + @motor_premiums

    # Profit calculations
    @gross_profit = @net_revenue * 0.3 rescue 0  # Assuming 30% margin
    @net_profit = @gross_profit - @total_commissions rescue 0
  end

  # GET /admin/reports/performance
  def performance
    @date_range = params[:date_range] || '30_days'

    case @date_range
    when '7_days'
      start_date = 7.days.ago
    when '30_days'
      start_date = 30.days.ago
    when '3_months'
      start_date = 3.months.ago
    when '6_months'
      start_date = 6.months.ago
    when '1_year'
      start_date = 1.year.ago
    else
      start_date = 30.days.ago
    end

    # Sales performance
    if defined?(Order)
      @total_sales = Order.where(created_at: start_date..Time.current).count
      @avg_order_value = Order.where(created_at: start_date..Time.current).average(:total_amount) || 0
      @conversion_rate = 0  # Would need visitor tracking to calculate
    elsif defined?(Booking)
      @total_sales = Booking.where(created_at: start_date..Time.current).count
      @avg_order_value = Booking.where(created_at: start_date..Time.current).average(:total_amount) || 0
      @conversion_rate = 0
    else
      @total_sales = 0
      @avg_order_value = 0
      @conversion_rate = 0
    end

    # Agent performance
    @top_agents = User.where(user_type: 'agent')
                     .joins(:life_insurances)
                     .where(life_insurances: { created_at: start_date..Time.current })
                     .group('users.id', 'users.first_name', 'users.last_name')
                     .order('COUNT(life_insurances.id) DESC')
                     .limit(10)
                     .pluck('users.first_name', 'users.last_name', 'COUNT(life_insurances.id)') rescue []

    # Product performance
    if defined?(Product)
      @top_performing_products = Product.joins(:order_items)
                                       .where(order_items: { created_at: start_date..Time.current })
                                       .group('products.id', 'products.name')
                                       .order('SUM(order_items.quantity * order_items.price) DESC')
                                       .limit(10)
                                       .pluck('products.name', 'SUM(order_items.quantity * order_items.price)') rescue []
    else
      @top_performing_products = []
    end

    # Customer metrics
    @new_customers = Customer.where(created_at: start_date..Time.current).count
    @repeat_customers = Customer.joins(:health_insurances)
                               .where(health_insurances: { created_at: start_date..Time.current })
                               .group('customers.id')
                               .having('COUNT(health_insurances.id) > 1')
                               .count.keys.count rescue 0

    @customer_retention_rate = @repeat_customers > 0 && @new_customers > 0 ?
                              ((@repeat_customers.to_f / @new_customers) * 100).round(2) : 0
  end
end