class Admin::CustomersController < Admin::ApplicationController
  include LocationData
  include ConfigurablePagination
  before_action :set_customer, only: [:show, :edit, :update, :destroy, :toggle_status, :policy_chart, :trace_commission, :product_selection]
  skip_before_action :ensure_admin, only: [:search_sub_agents]
  skip_before_action :authenticate_user!, only: [:search_sub_agents]
  skip_load_and_authorize_resource only: [:search_sub_agents]

  # GET /admin/customers
  def index
    # Check if policies_count column exists for optimized queries
    has_counter_cache = Customer.column_names.include?('policies_count')

    # Check if search is active first
    search_active = params[:search].present? && params[:search].strip.length >= 4

    if search_active
      # When search is active, use simpler query without select optimization to avoid pg_search conflicts
      @customers = Customer.all
    else
      # Use standard query and rely on counter cache for policy counts
      @customers = Customer.all
    end

    # Search functionality - only search if 4+ characters or empty
    if params[:search].present?
      search_term = params[:search].strip
      if search_term.length >= 4
        @customers = @customers.search_customers(search_term)
      elsif search_term.length > 0
        # Return empty result if search term is too short
        @customers = @customers.none
      end
    end

    # Filter by customer type - removed (column doesn't exist in customers table)

    # Filter by status - removed (status column doesn't exist in customers table)
    # All customers are considered active since there's no status field

    # Get total count before pagination for display purposes
    @total_filtered_count = @customers.count

    # Order and paginate using configurable pagination
    @customers = paginate_records(@customers.order(created_at: :desc))

    # Calculate statistics
    # Create a separate scope for statistics to avoid pg_search GROUP BY issues
    stats_scope = Customer.all

    # Apply filters but handle search differently for stats
    if params[:search].present? && params[:search].strip.length >= 4
      # For statistics, use a simple where clause instead of pg_search to avoid GROUP BY issues
      search_term = params[:search].strip
      stats_scope = stats_scope.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR company_name ILIKE ? OR email ILIKE ? OR mobile ILIKE ? OR pan_number ILIKE ?",
        "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"
      )
    end

    # customer_type filtering removed - column doesn't exist in customers table

    # Status filtering removed - status column doesn't exist in customers table
    # All customers are treated as active

    # Calculate filtered stats
    @stats = {
      total_customers: stats_scope.count,
      active_customers: stats_scope.where(status: true).count,
      new_this_month: stats_scope.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month).count
    }

    @total_customers = @stats[:total_customers]
    @active_customers = @stats[:active_customers]
    @new_this_month = @stats[:new_this_month]

    # Handle AJAX requests
    respond_to do |format|
      format.html # Regular HTML request
      format.json { render json: { customers: @customers, stats: @stats } }
    end
  end

  # GET /admin/customers/1
  def show
    # Simple customer show page without insurance dependencies
    @all_policies = []
    @policies = []
    @family_members = []
    @uploaded_documents = []
  end

  # GET /admin/customers/:id/policy_chart
  def policy_chart
    # Get all policy types and their status for this customer
    @policy_status = {
      'Health Insurance' => {
        exists: HealthInsurance.exists?(customer_id: @customer.id),
        count: HealthInsurance.where(customer_id: @customer.id).count,
        icon: 'bi-heart-pulse',
        color: 'info',
        policies: HealthInsurance.where(customer_id: @customer.id).includes(:customer)
      },
      'Life Insurance' => {
        exists: LifeInsurance.exists?(customer_id: @customer.id),
        count: LifeInsurance.where(customer_id: @customer.id).count,
        icon: 'bi-shield-check',
        color: 'primary',
        policies: LifeInsurance.where(customer_id: @customer.id).includes(:customer)
      },
      'Motor Insurance' => {
        exists: MotorInsurance.exists?(customer_id: @customer.id),
        count: MotorInsurance.where(customer_id: @customer.id).count,
        icon: 'bi-car-front',
        color: 'warning',
        policies: MotorInsurance.where(customer_id: @customer.id).includes(:customer)
      },
      'Other Insurance' => {
        exists: defined?(OtherInsurance) && OtherInsurance.exists?(customer_id: @customer.id),
        count: defined?(OtherInsurance) ? OtherInsurance.where(customer_id: @customer.id).count : 0,
        icon: 'bi-grid-3x3',
        color: 'secondary',
        policies: defined?(OtherInsurance) ? OtherInsurance.where(customer_id: @customer.id).includes(:customer) : []
      }
    }

    # Calculate totals
    @total_policies = @policy_status.values.sum { |policy| policy[:count] }
    @policy_types_with_coverage = @policy_status.count { |_, policy| policy[:exists] }
    @coverage_percentage = @policy_types_with_coverage > 0 ? (@policy_types_with_coverage.to_f / @policy_status.keys.count * 100).round(1) : 0
  end

  # GET /admin/customers/:id/trace_commission
  def trace_commission
    # Get all policy types and their status for this customer
    @policy_status = {
      'Health Insurance' => {
        opted: HealthInsurance.exists?(customer_id: @customer.id),
        count: HealthInsurance.where(customer_id: @customer.id).count,
        icon: 'bi-heart-pulse',
        color: 'success',
        policies: HealthInsurance.where(customer_id: @customer.id),
        total_premium: HealthInsurance.where(customer_id: @customer.id).sum(:total_premium) || 0,
        latest_policy: HealthInsurance.where(customer_id: @customer.id).order(:created_at).last
      },
      'Life Insurance' => {
        opted: LifeInsurance.exists?(customer_id: @customer.id),
        count: LifeInsurance.where(customer_id: @customer.id).count,
        icon: 'bi-shield-check',
        color: 'primary',
        policies: LifeInsurance.where(customer_id: @customer.id),
        total_premium: LifeInsurance.where(customer_id: @customer.id).sum(:total_premium) || 0,
        latest_policy: LifeInsurance.where(customer_id: @customer.id).order(:created_at).last
      },
      'Motor Insurance' => {
        opted: MotorInsurance.exists?(customer_id: @customer.id),
        count: MotorInsurance.where(customer_id: @customer.id).count,
        icon: 'bi-car-front',
        color: 'warning',
        policies: MotorInsurance.where(customer_id: @customer.id),
        total_premium: MotorInsurance.where(customer_id: @customer.id).sum(:total_premium) || 0,
        latest_policy: MotorInsurance.where(customer_id: @customer.id).order(:created_at).last
      }
    }

    # Get comprehensive product status (handling cases where tables might not exist yet)
    @product_status = {}

    # Insurance Products
    @product_status['Life'] = @policy_status['Life Insurance'][:opted]
    @product_status['Health'] = @policy_status['Health Insurance'][:opted]
    @product_status['Motor'] = @policy_status['Motor Insurance'][:opted]
    @product_status['General'] = false # Placeholder for General Insurance
    @product_status['Travel Insurance'] = false # Placeholder for Travel Insurance

    # Investment Products (check if tables exist)
    begin
      @product_status['Mutual Fund'] = @customer.respond_to?(:investments) ?
        @customer.investments.where(investment_type: 'Mutual Fund').exists? : false
      @product_status['Gold'] = @customer.respond_to?(:investments) ?
        @customer.investments.where(investment_type: 'Gold').exists? : false
      @product_status['NPS'] = @customer.respond_to?(:investments) ?
        @customer.investments.where(investment_type: 'NPS').exists? : false
      @product_status['Bonds'] = @customer.respond_to?(:investments) ?
        @customer.investments.where(investment_type: 'Bonds').exists? : false
    rescue
      @product_status['Mutual Fund'] = false
      @product_status['Gold'] = false
      @product_status['NPS'] = false
      @product_status['Bonds'] = false
    end

    # Loan Products
    begin
      @product_status['Personal'] = @customer.respond_to?(:loans) ?
        @customer.loans.where(loan_type: 'Personal').exists? : false
      @product_status['Home'] = @customer.respond_to?(:loans) ?
        @customer.loans.where(loan_type: 'Home').exists? : false
      @product_status['Business'] = @customer.respond_to?(:loans) ?
        @customer.loans.where(loan_type: 'Business').exists? : false
    rescue
      @product_status['Personal'] = false
      @product_status['Home'] = false
      @product_status['Business'] = false
    end

    # Tax Services
    begin
      @product_status['ITR'] = @customer.respond_to?(:tax_services) ?
        @customer.tax_services.where(service_type: 'ITR Filing').exists? : false
    rescue
      @product_status['ITR'] = false
    end

    # Travel Services
    begin
      @product_status['Domestic'] = @customer.respond_to?(:travel_packages) ?
        @customer.travel_packages.where(travel_type: 'Domestic').exists? : false
      @product_status['International'] = @customer.respond_to?(:travel_packages) ?
        @customer.travel_packages.where(travel_type: 'International').exists? : false
    rescue
      @product_status['Domestic'] = false
      @product_status['International'] = false
    end

    # Additional placeholder products for future expansion
    @product_status['Additional 1'] = false
    @product_status['Additional 2'] = false

    # Calculate comprehensive commission data based on all 17 products
    total_policies = 0
    total_premium = 0
    opted_count = @product_status.values.count(true)

    # Count actual policies and premiums from existing insurance types
    total_policies += @policy_status.values.sum { |policy| policy[:count] }
    total_premium += @policy_status.values.sum { |policy| policy[:total_premium] }

    # Add counts from other product types (when they have data)
    begin
      if @customer.respond_to?(:investments)
        total_policies += @customer.investments.count
        total_premium += @customer.investments.sum(:investment_amount) || 0
      end

      if @customer.respond_to?(:loans)
        total_policies += @customer.loans.count
        total_premium += @customer.loans.sum(:loan_amount) || 0
      end

      if @customer.respond_to?(:tax_services)
        total_policies += @customer.tax_services.count
        total_premium += @customer.tax_services.sum(:amount) || 0
      end

      if @customer.respond_to?(:travel_packages)
        total_policies += @customer.travel_packages.count
        total_premium += @customer.travel_packages.sum(:package_amount) || 0
      end
    rescue
      # Handle cases where tables don't exist yet
    end

    @commission_summary = {
      total_premium: total_premium,
      total_policies: total_policies,
      opted_count: opted_count,
      total_products: 17, # Total number of product types available
      coverage_percentage: (opted_count.to_f / 17 * 100).round(1)
    }

    # Get commission payouts for this customer's policies
    @commission_payouts = CommissionPayout.joins(
      "LEFT JOIN health_insurances ON commission_payouts.policy_type = 'health' AND commission_payouts.policy_id = health_insurances.id
       LEFT JOIN life_insurances ON commission_payouts.policy_type = 'life' AND commission_payouts.policy_id = life_insurances.id
       LEFT JOIN motor_insurances ON commission_payouts.policy_type = 'motor' AND commission_payouts.policy_id = motor_insurances.id"
    ).where(
      "(commission_payouts.policy_type = 'health' AND health_insurances.customer_id = ?) OR
       (commission_payouts.policy_type = 'life' AND life_insurances.customer_id = ?) OR
       (commission_payouts.policy_type = 'motor' AND motor_insurances.customer_id = ?)",
      @customer.id, @customer.id, @customer.id
    ).includes(:payout_audit_logs)
  end

  # GET /admin/customers/new
  def new
    @customer = Customer.new
    # status field removed - column doesn't exist in customers table
    @sub_agents = SubAgent.active.order(:first_name, :last_name)

    # If lead_id is provided, populate customer with lead data
    if params[:lead_id].present?
      @lead = Lead.find(params[:lead_id])

      # Basic information mapping
      # customer_type assignment removed - field doesn't exist in customers table
      @customer.email = @lead.email
      @customer.mobile = @lead.contact_number
      # address, city, state columns don't exist in customers table

      # Individual customer mapping
      if @lead.individual?
        @customer.first_name = @lead.first_name
        @customer.middle_name = @lead.middle_name
        @customer.last_name = @lead.last_name
        # Most other columns don't exist in customers table
      # Corporate customer mapping
      elsif @lead.corporate?
        # company_name column doesn't exist in customers table
        # Most other columns don't exist either
      else
        # Fallback for legacy data
        @customer.first_name = extract_first_name(@lead.name)
        @customer.last_name = extract_last_name(@lead.name)
      end

      # Most fields don't exist in customers table - removed assignments
    end
  end

  # GET /admin/customers/1/edit
  def edit
  end

  # POST /admin/customers
  def create
    # Extract password params separately before creating customer
    password = params[:customer][:password]
    password_confirmation = params[:customer][:password_confirmation]
    user_enter_password = params[:customer][:user_enter_password]

    @customer = Customer.new(customer_params)

    # Set the password attributes manually
    @customer.password = password
    @customer.password_confirmation = password_confirmation

    begin
      ActiveRecord::Base.transaction do
        if @customer.save
          # Update lead if customer was created from a lead (commented out until lead_id column exists)
          # if @customer.lead_id.present?
          #   lead = Lead.find_by(lead_id: @customer.lead_id)
          #   if lead
          #     lead.update!(
          #       current_stage: 'converted',
          #       converted_customer_id: @customer.id,
          #       stage_updated_at: Time.current
          #     )
          #   end
          # end

          # Always create User account for consistency with mobile API
          # Create User account - auto-generate password if not provided
          should_create_user = @customer.email.present? # Always create user if email exists

          if should_create_user
            if password.present? && password_confirmation.present?
              # Use provided password
              if password == password_confirmation
                generated_password = password
                User.create!(
                  first_name: @customer.first_name,
                  last_name: @customer.last_name,
                  middle_name: @customer.middle_name,
                  email: @customer.email,
                  mobile: @customer.mobile,
                  password: generated_password,
                  password_confirmation: generated_password,
                  user_type: 'customer',
                  address: @customer.address,
                  city: params[:customer][:city] || 'Unknown',
                  state: params[:customer][:state] || 'Unknown',
                  pincode: params[:customer][:pincode] || '000000',
                  country: 'India',  # Match mobile API default
                  status: true,
                  is_active: true,
                  is_verified: false
                )
                redirect_to admin_customer_path(@customer), notice: 'Customer and login account created successfully.'
              else
                @customer.destroy
                @customer.errors.add(:password_confirmation, "doesn't match Password")
                @sub_agents = SubAgent.active.order(:first_name, :last_name)
                render :new, status: :unprocessable_entity
                return
              end
            else
              # Auto-generate password if no password provided but user account creation requested
              generated_password = generate_secure_password
              User.create!(
                first_name: @customer.first_name,
                last_name: @customer.last_name,
                middle_name: @customer.middle_name,
                email: @customer.email,
                mobile: @customer.mobile,
                password: generated_password,
                password_confirmation: generated_password,
                user_type: 'customer',
                address: @customer.address,
                city: params[:customer][:city] || 'Unknown',
                state: params[:customer][:state] || 'Unknown',
                pincode: params[:customer][:pincode] || '000000',
                country: 'India',  # Match mobile API default
                status: true,
                is_active: true,
                is_verified: false
              )
              # Store generated password in flash for display (in production, send via email/SMS)
              flash[:generated_password] = generated_password
              redirect_to admin_customer_path(@customer),
                         notice: "Customer created successfully. Auto-generated password: #{generated_password}"
            end
          else
            redirect_to admin_customer_path(@customer), notice: 'Customer was successfully created.'
          end
        else
          @sub_agents = SubAgent.active.order(:first_name, :last_name)
          render :new, status: :unprocessable_entity
        end
      end
    rescue => e
      @customer.errors.add(:base, "Failed to create login account: #{e.message}")
      @sub_agents = SubAgent.active.order(:first_name, :last_name)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/customers/1
  def update
    if @customer.update(customer_params)
      redirect_to admin_customer_path(@customer), notice: 'Customer was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/customers/1
  def destroy
    # Check if customer has any associated records that would prevent deletion
    has_bookings = @customer.bookings.exists?
    has_orders = @customer.orders.exists?
    has_subscriptions = @customer.milk_subscriptions.exists?

    if has_bookings || has_orders || has_subscriptions
      associated_items = []
      associated_items << "bookings" if has_bookings
      associated_items << "orders" if has_orders
      associated_items << "subscriptions" if has_subscriptions

      redirect_to admin_customers_path, alert: "Cannot delete customer with existing #{associated_items.join(', ')}."
    else
      @customer.destroy
      redirect_to admin_customers_path, notice: 'Customer was successfully deleted.'
    end
  end

  # PATCH /admin/customers/1/toggle_status
  def toggle_status
    # Check if status column exists or use virtual attribute
    if @customer.respond_to?(:status)
      current_status = @customer.status.nil? ? true : @customer.status
      @customer.update(status: !current_status)
      status_text = @customer.status ? 'enabled' : 'disabled'

      respond_to do |format|
        format.html { redirect_back(fallback_location: edit_admin_customer_path(@customer), notice: "Customer has been #{status_text}.") }
        format.json { render json: { status: @customer.status, message: "Customer #{status_text}" } }
        format.js {
          render inline: "window.location.reload();"
        }
      end
    else
      redirect_to admin_customers_path, alert: "Status functionality requires database migration."
    end
  end

  # GET /admin/customers/export
  def export
    @customers = Customer.includes(:policies)

    # Apply same filters as index
    if params[:search].present?
      @customers = @customers.search_customers(params[:search])
    end

    # customer_type filtering removed - column doesn't exist in customers table

    case params[:status]
    when 'active'
      @customers = @customers.active
    when 'inactive'
      @customers = @customers.inactive
    end

    @customers = @customers.order(:created_at)

    respond_to do |format|
      format.csv do
        send_data generate_customers_csv(@customers), filename: "customers_#{Date.current}.csv"
      end
      # format.xlsx do
      #   send_data generate_customers_xlsx(@customers), filename: "customers_#{Date.current}.xlsx"
      # end
    end
  end

  # GET /admin/customers/:id/product_selection
  def product_selection
    # Available products for selection
    @products = [
      { name: 'Health Insurance', path: new_admin_health_insurance_path(customer_id: @customer.id), icon: 'heart-pulse', description: 'Medical coverage and health protection' },
      { name: 'Life Insurance', path: new_admin_life_insurance_path(customer_id: @customer.id), icon: 'shield-heart', description: 'Life coverage and financial security' },
      { name: 'Motor Insurance', path: new_admin_motor_insurance_path(customer_id: @customer.id), icon: 'car-front', description: 'Vehicle insurance coverage' },
      { name: 'Investment', path: '#', icon: 'graph-up', description: 'Investment opportunities and plans' },
      { name: 'Loans', path: '#', icon: 'cash-coin', description: 'Personal and business loan options' },
      { name: 'Tax Services', path: '#', icon: 'receipt', description: 'Tax planning and consultation' },
      { name: 'Travel Packages', path: '#', icon: 'airplane', description: 'Travel insurance and packages' }
    ]
  end

  # API endpoint for cities
  def cities
    state = params[:state]
    query = params[:query]

    # Return all cities for the selected state
    cities = LocationData.cities_for_state(state)

    render json: { cities: cities }
  end

  # API endpoint for searching sub agents (affiliates)
  def search_sub_agents
    query = params[:q] || params[:query]
    limit = params[:limit]&.to_i || 20
    affiliates = []

    if query.present? && query.strip.length >= 2
      # Search with query
      affiliates = SubAgent.active
                          .where("LOWER(first_name || ' ' || last_name) ILIKE ?", "%#{query.downcase}%")
                          .limit(limit)
                          .map { |agent| { id: agent.id, text: agent.display_name } }
    elsif query.blank? || query.strip.empty?
      # Return default affiliates when no search query (show recently active or all)
      affiliates = SubAgent.active
                          .order(:first_name, :last_name)
                          .limit([limit, 10].min) # Show max 10 when no search
                          .map { |agent| { id: agent.id, text: agent.display_name } }
    end

    render json: { results: affiliates }
  end

  private

  # Generate a secure password for auto-creation
  def generate_secure_password
    # Generate password in format: first 4 letters of name + @ + current year
    # Example: PRAMOD becomes PRAM@2024

    # Get first name - use first_name from customer
    first_name = @customer.first_name.to_s.strip.upcase

    # Get first 4 characters of name, pad with 'X' if less than 4 characters
    name_part = first_name[0..3].ljust(4, 'X')

    # Use current year since birth_date column doesn't exist
    year_part = Date.current.year.to_s

    "#{name_part}@#{year_part}"
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    # Only permit fields that actually exist in the customers table
    params.require(:customer).permit(
      :first_name, :last_name, :middle_name, :email, :mobile,
      :longitude, :latitude, :whatsapp_number, :auto_generated_password,
      :location_obtained_at, :location_accuracy, :password, :password_confirmation,
      :birth_date, :gender, :marital_status, :pan_no, :gst_no,
      :company_name, :occupation, :annual_income,
      :emergency_contact_name, :emergency_contact_number, :blood_group,
      :nationality, :preferred_language, :notes, :address, :status,
      :personal_image, :house_image, profile_image: []
    )
  end

  def generate_customers_csv(customers)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << %w[
        ID FirstName MiddleName LastName Email Mobile
        WhatsappNumber Longitude Latitude LocationAccuracy LocationObtainedAt CreatedAt
      ]

      customers.find_each do |customer|
        csv << [
          customer.id,
          customer.first_name,
          customer.middle_name,
          customer.last_name,
          customer.email,
          customer.mobile,
          customer.whatsapp_number,
          customer.longitude,
          customer.latitude,
          customer.location_accuracy,
          customer.location_obtained_at,
          customer.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end

  def generate_customers_xlsx(customers)
    require 'rubyXL'

    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.sheet_name = 'Customers'

    # Headers
    headers = %w[
      ID CustomerType FirstName LastName CompanyName Email Mobile
      Address State City Pincode BirthDate Gender Height Weight
      Education MaritalStatus Occupation JobName TypeOfDuty AnnualIncome
      PANNumber GSTNumber BirthPlace NomineeName NomineeRelation
      NomineeDOB Status AddedBy CreatedAt
    ]

    headers.each_with_index do |header, index|
      worksheet.add_cell(0, index, header)
      worksheet.sheet_data[0][index].change_font_bold(true)
    end

    # Data rows
    customers.each_with_index do |customer, row_index|
      row = row_index + 1
      data = [
        customer.id,
        customer.first_name,
        customer.last_name,
        customer.company_name,
        customer.email,
        customer.mobile,
        customer.address,
        customer.state,
        customer.city,
        customer.pincode,
        customer.birth_date,
        customer.gender&.humanize,
        customer.height,
        customer.weight,
        customer.education,
        customer.marital_status&.humanize,
        customer.occupation,
        customer.job_name,
        customer.type_of_duty,
        customer.annual_income,
        customer.pan_number,
        customer.gst_number,
        customer.birth_place,
        customer.nominee_name,
        customer.nominee_relation,
        customer.nominee_date_of_birth,
        customer.status? ? 'Active' : 'Inactive',
        customer.added_by&.humanize,
        customer.created_at.strftime('%Y-%m-%d %H:%M:%S')
      ]

      data.each_with_index do |value, col_index|
        worksheet.add_cell(row, col_index, value)
      end
    end

    workbook.stream.string
  end

  def extract_first_name(full_name)
    full_name.to_s.split(' ').first || 'Unknown'
  end

  def extract_last_name(full_name)
    names = full_name.to_s.split(' ')
    names.length > 1 ? names[1..-1].join(' ') : 'Unknown'
  end

  # Calculate age from birth date with detailed format (years and days)
  def calculate_age(birth_date)
    return '' unless birth_date

    today = Date.current

    # Calculate years
    years = today.year - birth_date.year

    # Calculate if birthday hasn't occurred this year yet
    if today.month < birth_date.month || (today.month == birth_date.month && today.day < birth_date.day)
      years -= 1
    end

    if years == 0
      # If less than a year old, calculate days from birth
      days = (today - birth_date).to_i
      "#{days} days"
    else
      # Calculate days since last birthday
      last_birthday = Date.new(today.year, birth_date.month, birth_date.day)
      if last_birthday > today
        last_birthday = Date.new(today.year - 1, birth_date.month, birth_date.day)
      end

      days = (today - last_birthday).to_i

      if days == 0
        "#{years} years"
      else
        "#{years} years, #{days} days"
      end
    end
  end
end