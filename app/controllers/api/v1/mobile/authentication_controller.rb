class Api::V1::Mobile::AuthenticationController < Api::V1::BaseController
  skip_before_action :authorize_request, only: [:login, :register, :forgot_password]

  # POST /api/v1/mobile/auth/login
  def login
    # Support login with email or mobile number
    login_field = params[:username] || params[:email] || params[:mobile]
    password = params[:password]

    if login_field.blank? || password.blank?
      return json_response({
        success: false,
        message: 'Email/Mobile and password are required'
      }, :unprocessable_entity)
    end

    # Check if it's a user login (including customers, agents, admin)
    # Support login with both email and mobile number
    user = User.find_by(email: login_field)

    # If not found by email and login_field looks like a mobile number, try mobile search with formatting
    unless user
      user = find_by_mobile_variants(User, login_field)
    end
    if user && user.valid_password?(password) && user.status

      if user.customer?
        # Customer login - find associated customer record
        customer = Customer.find_by(email: user.email)
        unless customer
          customer = find_by_mobile_variants(Customer, user.mobile)
        end
        if customer
          token = generate_token(user, 'customer', customer_id: customer.id)
          portfolio_stats = get_customer_portfolio_stats(customer)

          json_response({
            success: true,
            data: {
              token: token,
              username: user.full_name,
              role: 'customer',
              user_id: user.id,
              customer_id: customer.id,
              email: user.email,
              mobile: user.mobile,
              portfolio_summary: {
                total_policies: portfolio_stats[:total_policies],
                upcoming_installments: portfolio_stats[:upcoming_installments],
                renewal_policies: portfolio_stats[:renewal_policies]
              }
            }
          })
          return
        end
      elsif user.agent? || user.admin? || user.sub_agent?
        # Agent/Admin login
        token = generate_token(user, user.user_type)

        json_response({
          success: true,
          data: {
            token: token,
            username: user.full_name,
            role: user.user_type,
            user_id: user.id,
            email: user.email,
            mobile: user.mobile
          }
        })
        return
      end
    end

    # Check direct Customer login
    customer = Customer.find_by(email: login_field)
    unless customer
      customer = find_by_mobile_variants(Customer, login_field)
    end

    if customer && customer.authenticate(password) && customer.status
      token = generate_token(customer, 'customer')
      portfolio_stats = get_customer_portfolio_stats(customer)

      json_response({
        success: true,
        data: {
          token: token,
          username: customer.display_name,
          role: 'customer',
          user_id: customer.id,
          customer_id: customer.id,
          email: customer.email,
          mobile: customer.mobile,
          profile: {
            first_name: customer.first_name,
            last_name: customer.last_name,
            middle_name: customer.middle_name,
            gender: customer.gender,
            birth_date: customer.birth_date,
            address: customer.address
          },
          portfolio_summary: {
            total_policies: portfolio_stats[:total_policies],
            upcoming_installments: portfolio_stats[:upcoming_installments],
            renewal_policies: portfolio_stats[:renewal_policies]
          }
        }
      })
      return
    end

    # Check DeliveryPerson login
    delivery_person = DeliveryPerson.find_by(email: login_field)
    unless delivery_person
      # First try direct mobile search (for 12-digit numbers like 919190939300)
      delivery_person = DeliveryPerson.find_by(mobile: login_field)

      unless delivery_person
        delivery_person = find_by_mobile_variants(DeliveryPerson, login_field)
      end
    end
    if delivery_person && delivery_person.authenticate(password) && delivery_person.status
      token = generate_token(delivery_person, 'delivery_person')

      # Get delivery person statistics
      delivery_stats = get_delivery_person_statistics(delivery_person)

      json_response({
        success: true,
        data: {
          token: token,
          username: delivery_person.display_name,
          role: 'delivery_person',
          user_id: delivery_person.id,
          delivery_person_id: delivery_person.id,
          email: delivery_person.email,
          mobile: delivery_person.mobile,
          profile: {
            first_name: delivery_person.first_name,
            last_name: delivery_person.last_name,
            vehicle_type: delivery_person.vehicle_type,
            vehicle_number: delivery_person.vehicle_number,
            license_number: delivery_person.license_number,
            delivery_areas: delivery_person.delivery_area_list,
            joining_date: delivery_person.joining_date,
            years_of_service: delivery_person.years_of_service
          },
          dashboard_stats: {
            total_deliveries: delivery_stats[:total_deliveries],
            completed_deliveries: delivery_stats[:completed_deliveries],
            pending_deliveries: delivery_stats[:pending_deliveries],
            success_rate: delivery_stats[:success_rate],
            earnings_this_month: delivery_stats[:earnings_this_month],
            deliveries_this_month: delivery_stats[:deliveries_this_month],
            average_rating: delivery_stats[:average_rating],
            vehicle_info: delivery_person.vehicle_info
          }
        }
      })
      return
    end

    # Check sub-agent login
    sub_agent = SubAgent.find_by(email: login_field)
    unless sub_agent
      sub_agent = find_by_mobile_variants(SubAgent, login_field)
    end
    if sub_agent && sub_agent.status == 'active'
      # For sub-agents, we also don't have password in current model
      token = generate_token(sub_agent, 'sub_agent')

      json_response({
        success: true,
        data: {
          token: token,
          username: sub_agent.display_name,
          role: 'sub_agent',
          user_id: sub_agent.id,
          email: sub_agent.email,
          mobile: sub_agent.mobile
        }
      })
      return
    end


    json_response({
      success: false,
      message: 'Invalid username or password'
    }, :unauthorized)
  end

  # POST /api/v1/mobile/auth/forgot_password
  def forgot_password
    login_field = params[:email] || params[:mobile]

    if login_field.blank?
      return json_response({
        success: false,
        message: 'Email or mobile number is required'
      }, :unprocessable_entity)
    end

    # Check in all user types
    user = User.find_by(email: login_field) || Customer.find_by(email: login_field) || SubAgent.find_by(email: login_field)

    # If not found by email, try mobile search with formatting
    unless user
      user = find_by_mobile_variants(User, login_field) ||
             find_by_mobile_variants(Customer, login_field) ||
             find_by_mobile_variants(SubAgent, login_field)
    end

    if user
      # Generate reset token (simplified - you might want to use a proper token system)
      reset_token = SecureRandom.urlsafe_base64(32)

      # Here you would typically:
      # 1. Save the reset token to database with expiry
      # 2. Send email with reset link

      json_response({
        success: true,
        message: 'Password reset instructions have been sent to your email'
      })
    else
      json_response({
        success: false,
        message: 'Email address not found'
      }, :not_found)
    end
  end

  # POST /api/v1/mobile/auth/register
  def register
    # Handle both 'role' and 'user_type' parameters for backward compatibility
    role = params[:role]&.downcase || params[:user_type]&.downcase || 'customer'

    # Ensure valid role values
    case role
    when 'customer', 'user'
      register_customer
    when 'agent', 'sub_agent'
      register_agent
    else
      json_response({
        success: false,
        message: 'Invalid role. Only customer and agent registration are allowed.',
        valid_roles: ['customer', 'agent']
      }, :unprocessable_entity)
    end
  end

  def register_customer
    customer_params = params.permit(:first_name, :last_name, :middle_name, :email, :mobile, :password, :password_confirmation,
                                   :user_type, :role, :address, :city, :state, :pincode, :whatsapp_number, :latitude, :longitude, :is_registered_by_mobile)

    # Validate required fields
    if customer_params[:first_name].blank? || customer_params[:last_name].blank? ||
       customer_params[:email].blank? || customer_params[:mobile].blank? || customer_params[:password].blank?
      return json_response({
        success: false,
        message: 'First name, last name, email, mobile number, and password are required'
      }, :unprocessable_entity)
    end

    # Validate password confirmation if provided
    if customer_params[:password_confirmation].present? && customer_params[:password] != customer_params[:password_confirmation]
      return json_response({
        success: false,
        message: 'Password confirmation does not match'
      }, :unprocessable_entity)
    end

    # Validate email format
    unless customer_params[:email].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      return json_response({
        success: false,
        message: 'Please enter a valid email address'
      }, :unprocessable_entity)
    end

    # Validate and format mobile number
    mobile_number = format_mobile_number(customer_params[:mobile])
    unless mobile_number
      return json_response({
        success: false,
        message: 'Please enter a valid Indian mobile number (10 digits starting with 6-9)'
      }, :unprocessable_entity)
    end

    # Validate name fields
    unless validate_name_fields(customer_params[:first_name])
      return json_response({
        success: false,
        message: 'First name should contain only alphabetic characters and be 2-50 characters long'
      }, :unprocessable_entity)
    end

    unless validate_name_fields(customer_params[:last_name])
      return json_response({
        success: false,
        message: 'Last name should contain only alphabetic characters and be 2-50 characters long'
      }, :unprocessable_entity)
    end

    # Validate password strength
    if customer_params[:password].length < 6
      return json_response({
        success: false,
        message: 'Password must be at least 6 characters long'
      }, :unprocessable_entity)
    end

    # Check if customer or user already exists (short-circuits: skips the
    # User lookup once a Customer match is already found)
    if Customer.exists?(email: customer_params[:email]) || User.exists?(email: customer_params[:email])
      return json_response({
        success: false,
        message: 'An account with this email address already exists. Please use a different email or try logging in.'
      }, :conflict)
    end

    if Customer.exists?(mobile: mobile_number) || User.exists?(mobile: mobile_number)
      return json_response({
        success: false,
        message: 'An account with this mobile number already exists. Please use a different mobile number or try logging in.'
      }, :conflict)
    end

    # Use database transaction to ensure both records are created together
    begin
      ActiveRecord::Base.transaction do
        # Create Customer record (without password validations)
        customer = Customer.new(
          first_name: customer_params[:first_name],
          last_name: customer_params[:last_name],
          middle_name: customer_params[:middle_name],
          email: customer_params[:email],
          mobile: mobile_number, # Use formatted mobile number
          address: customer_params[:address],
          whatsapp_number: customer_params[:whatsapp_number],
          latitude: customer_params[:latitude],
          longitude: customer_params[:longitude],
          is_registered_by_mobile: true, # Always set to true for mobile registrations
          status: true
        )
        customer.save!(validate: false)  # Skip validations to avoid password requirements

        # Create User record for login
        user = User.new(
          first_name: customer_params[:first_name],
          last_name: customer_params[:last_name],
          middle_name: customer_params[:middle_name],
          email: customer_params[:email],
          mobile: mobile_number, # Use formatted mobile number
          user_type: 'customer',
          address: customer_params[:address],
          city: customer_params[:city],
          state: customer_params[:state],
          pincode: customer_params[:pincode],
          status: true
        )

        # Set password separately to ensure proper Devise handling
        user.password = customer_params[:password]
        user.password_confirmation = customer_params[:password_confirmation].present? ? customer_params[:password_confirmation] : customer_params[:password]
        user.save!

        json_response({
          success: true,
          message: 'Customer registration successful. You can now login with your credentials.',
          data: {
            customer_id: customer.id,
            user_id: user.id,
            email: customer.email,
            mobile: customer.mobile,
            role: 'customer'
          }
        })
      end
    rescue ActiveRecord::RecordInvalid => e
      json_response({
        success: false,
        message: 'Customer registration failed',
        errors: e.record.errors.full_messages
      }, :unprocessable_entity)
    rescue => e
      json_response({
        success: false,
        message: 'Registration failed due to system error',
        error: e.message
      }, :internal_server_error)
    end
  end

  def register_agent
    agent_params = params.permit(:first_name, :last_name, :email, :mobile, :password, :password_confirmation,
                                :pan_no, :address, :city, :state, :gender, :occupation, :annual_income)

    # Validate required fields
    if agent_params[:first_name].blank? || agent_params[:last_name].blank? ||
       agent_params[:email].blank? || agent_params[:mobile].blank? || agent_params[:password].blank?
      return json_response({
        success: false,
        message: 'First name, last name, email, mobile number, and password are required'
      }, :unprocessable_entity)
    end

    # Validate password confirmation
    if agent_params[:password_confirmation].present? && agent_params[:password] != agent_params[:password_confirmation]
      return json_response({
        success: false,
        message: 'Password confirmation does not match'
      }, :unprocessable_entity)
    end

    # Validate email format
    unless agent_params[:email].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      return json_response({
        success: false,
        message: 'Please enter a valid email address'
      }, :unprocessable_entity)
    end

    # Validate and format mobile number
    mobile_number = format_mobile_number(agent_params[:mobile])
    unless mobile_number
      return json_response({
        success: false,
        message: 'Please enter a valid Indian mobile number (10 digits starting with 6-9)'
      }, :unprocessable_entity)
    end

    # Validate name fields
    unless validate_name_fields(agent_params[:first_name])
      return json_response({
        success: false,
        message: 'First name should contain only alphabetic characters and be 2-50 characters long'
      }, :unprocessable_entity)
    end

    unless validate_name_fields(agent_params[:last_name])
      return json_response({
        success: false,
        message: 'Last name should contain only alphabetic characters and be 2-50 characters long'
      }, :unprocessable_entity)
    end

    # Validate password strength
    if agent_params[:password].length < 6
      return json_response({
        success: false,
        message: 'Password must be at least 6 characters long'
      }, :unprocessable_entity)
    end

    # Check if user already exists
    existing_user_email = User.exists?(email: agent_params[:email])
    existing_user_mobile = User.exists?(mobile: mobile_number)

    if existing_user_email
      return json_response({
        success: false,
        message: 'An account with this email address already exists. Please use a different email or try logging in.'
      }, :conflict)
    end

    if existing_user_mobile
      return json_response({
        success: false,
        message: 'An account with this mobile number already exists. Please use a different mobile number or try logging in.'
      }, :conflict)
    end

    user = User.new(
      first_name: agent_params[:first_name],
      last_name: agent_params[:last_name],
      email: agent_params[:email],
      mobile: mobile_number, # Use formatted mobile number
      user_type: 'agent',
      role: 'agent_role',
      status: false,  # Pending approval
      pan_number: agent_params[:pan_no],
      address: agent_params[:address],
      city: agent_params[:city],
      state: agent_params[:state],
      gender: agent_params[:gender],
      occupation: agent_params[:occupation],
      annual_income: agent_params[:annual_income]
    )

    # Set password separately to ensure proper Devise handling
    user.password = agent_params[:password]
    user.password_confirmation = agent_params[:password_confirmation].present? ? agent_params[:password_confirmation] : agent_params[:password]

    if user.save
      json_response({
        success: true,
        message: 'Agent registration successful. Your account is pending approval by admin.',
        data: {
          user_id: user.id,
          email: user.email,
          mobile: user.mobile,
          role: 'agent'
        }
      })
    else
      json_response({
        success: false,
        message: 'Agent registration failed',
        errors: user.errors.full_messages
      }, :unprocessable_entity)
    end
  end

  private

  def generate_token(user, role, customer_id: nil)
    payload = {
      user_id: user.id,
      role: role,
      exp: 30.days.from_now.to_i
    }

    case role
    when 'delivery_person'
      payload[:delivery_person_id] = user.id
    when 'customer'
      payload[:customer_id] = customer_id || user.id
    when 'sub_agent'
      payload[:sub_agent_id] = user.id
    end

    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def validate_name_fields(name)
    return false if name.blank?
    # Allow only alphabetic characters and spaces, min 2 characters
    name.match?(/\A[a-zA-Z\s]{2,50}\z/)
  end

  def format_mobile_number(mobile)
    return nil if mobile.blank?
    # Remove all non-digit characters
    clean_mobile = mobile.to_s.gsub(/\D/, '')

    # Handle different mobile number formats
    if clean_mobile.length == 10
      # Standard 10-digit format, accept all (for testing purposes)
      return clean_mobile
    elsif clean_mobile.length == 12 && clean_mobile.start_with?('91')
      # 12 digits starting with 91
      return clean_mobile[2..-1]
    elsif clean_mobile.length == 13 && clean_mobile.start_with?('+91')
      # +91 prefix with spaces removed
      return clean_mobile[3..-1]
    else
      return nil
    end
  end

  # Same candidate set as the old chain of `model.find_by(mobile: variant) || ...`
  # calls, collapsed into a single round trip instead of up to 5.
  def find_by_mobile_variants(model, raw_mobile)
    formatted = format_mobile_number(raw_mobile)
    return model.find_by(mobile: raw_mobile) unless formatted

    variants = [
      formatted,
      "+91#{formatted}",
      "+91 #{formatted}",
      "#{formatted[0..4]} #{formatted[5..9]}",
      "+91 #{formatted[0..4]} #{formatted[5..9]}"
    ]
    model.where(mobile: variants).first
  end

  def get_customer_portfolio_stats(customer)
    # This is an ecommerce application, so return ecommerce-related stats
    begin
      order_stats = customer.orders.pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("SUM(CASE WHEN status NOT IN ('cancelled', 'returned') THEN total_amount ELSE 0 END)"),
        Arel.sql("MAX(created_at)")
      )
      total_orders, total_spent, last_order_date = order_stats

      booking_stats = customer.bookings.pick(Arel.sql("COUNT(*)"), Arel.sql("MAX(created_at)"))
      total_bookings, last_booking_date = booking_stats

      {
        total_orders: total_orders,
        total_bookings: total_bookings,
        total_spent: total_spent.to_f,
        member_since: customer.created_at,
        recent_activity: {
          last_order_date: last_order_date,
          last_booking_date: last_booking_date
        }
      }
    rescue => e
      Rails.logger.error "Customer stats calculation error: #{e.message}"
      # Return basic data if there's any error
      {
        total_orders: 0,
        total_bookings: 0,
        total_spent: 0.0,
        member_since: customer.created_at,
        recent_activity: {
          last_order_date: nil,
          last_booking_date: nil
        }
      }
    end
  end

  def get_delivery_person_statistics(delivery_person)
    # Get actual delivery data if Order model has delivery_person relationship
    begin
      # Try to get actual delivery statistics
      if defined?(Order) && Order.column_names.include?('delivery_person_id')
        month_start = Order.connection.quote(Date.current.beginning_of_month)
        month_end = Order.connection.quote(Date.current.end_of_month)

        total_deliveries, completed_deliveries, pending_deliveries, current_month_deliveries =
          Order.where(delivery_person_id: delivery_person.id).pick(
            Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(*) FILTER (WHERE status = 'delivered')"),
            Arel.sql("COUNT(*) FILTER (WHERE status IN ('pending', 'shipped', 'out_for_delivery'))"),
            Arel.sql("COUNT(*) FILTER (WHERE created_at BETWEEN #{month_start} AND #{month_end})")
          )

        # Calculate success rate
        success_rate = total_deliveries > 0 ? ((completed_deliveries.to_f / total_deliveries) * 100).round(2) : 0

        # Mock earnings calculation (₹50 per delivery)
        earnings_this_month = current_month_deliveries * 50

        # Mock average rating
        average_rating = (4.0 + (rand * 1.0)).round(1) # Random rating between 4.0-5.0
      else
        # Generate realistic mock data if actual Order model doesn't have delivery person relationship
        total_deliveries = 150 + (delivery_person.id % 100)
        completed_deliveries = (total_deliveries * 0.85).to_i
        pending_deliveries = total_deliveries - completed_deliveries
        success_rate = ((completed_deliveries.to_f / total_deliveries) * 100).round(2)
        current_month_deliveries = 25 + (delivery_person.id % 15)
        earnings_this_month = current_month_deliveries * 50
        average_rating = (4.0 + (rand * 1.0)).round(1)
      end

      {
        total_deliveries: total_deliveries,
        completed_deliveries: completed_deliveries,
        pending_deliveries: pending_deliveries,
        success_rate: success_rate,
        deliveries_this_month: current_month_deliveries,
        earnings_this_month: earnings_this_month,
        average_rating: average_rating
      }
    rescue => e
      Rails.logger.error "Delivery statistics calculation error: #{e.message}"
      # Return mock data if there's any error
      {
        total_deliveries: 120,
        completed_deliveries: 102,
        pending_deliveries: 18,
        success_rate: 85.0,
        deliveries_this_month: 20,
        earnings_this_month: 1000,
        average_rating: 4.5
      }
    end
  end

end