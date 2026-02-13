class Admin::CustomersController < Admin::ApplicationController
  include LocationData
  include ConfigurablePagination
  before_action :set_customer, only: [:show, :edit, :update, :destroy, :policy_chart, :trace_commission, :product_selection]
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

    # Filter by status
    case params[:status]
    when 'active'
      @customers = @customers.where(status: true)
    when 'inactive'
      @customers = @customers.where(status: false)
    end

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

    case params[:status]
    when 'active'
      stats_scope = stats_scope.where(status: true)
    when 'inactive'
      stats_scope = stats_scope.where(status: false)
    end

    # Calculate filtered stats - customer_type column doesn't exist in customers table
    @stats = {
      total_customers: stats_scope.count,
      active_customers: stats_scope.count, # All customers are considered active in this context
      individual_customers: 0, # Not available without customer_type column
      corporate_customers: 0   # Not available without customer_type column
    }

    @total_customers = @stats[:total_customers]
    @active_customers = @stats[:active_customers]
    @individual_customers = @stats[:individual_customers]
    @corporate_customers = @stats[:corporate_customers]

    # Handle AJAX requests
    respond_to do |format|
      format.html # Regular HTML request
      format.json { render json: { customers: @customers, stats: @stats } }
    end
  end

  # GET /admin/customers/1
  def show
    @family_members = @customer.family_members.order(:created_at)
    @uploaded_documents = @customer.uploaded_documents.includes(file_attachment: :blob).order(:created_at)

    # Gather all policies from different insurance types
    @all_policies = []

    # Health Insurance policies
    @customer.health_insurances.each do |policy|
      @all_policies << {
        type: 'Health Insurance',
        policy: policy,
        policy_number: policy.policy_number,
        company_name: policy.insurance_company_name,
        premium: policy.total_premium,
        start_date: policy.policy_start_date,
        end_date: policy.policy_end_date,
        status: policy.active? ? 'Active' : 'Expired',
        created_at: policy.created_at
      }
    end

    # Life Insurance policies
    @customer.life_insurances.each do |policy|
      @all_policies << {
        type: 'Life Insurance',
        policy: policy,
        policy_number: policy.policy_number,
        company_name: policy.insurance_company_name,
        premium: policy.total_premium,
        start_date: policy.policy_start_date,
        end_date: policy.policy_end_date,
        status: policy.active? ? 'Active' : 'Expired',
        created_at: policy.created_at
      }
    end

    # Motor Insurance policies
    @customer.motor_insurances.each do |policy|
      @all_policies << {
        type: 'Motor Insurance',
        policy: policy,
        policy_number: policy.policy_number,
        company_name: policy.insurance_company_name,
        premium: policy.total_premium,
        start_date: policy.policy_start_date,
        end_date: policy.policy_end_date,
        status: policy.active? ? 'Active' : 'Expired',
        created_at: policy.created_at
      }
    end

    # Sort all policies by creation date (newest first)
    @all_policies.sort_by! { |p| p[:created_at] }.reverse!

    # For backwards compatibility, set @policies
    @policies = @all_policies
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
    @customer.status = true
    @sub_agents = SubAgent.active.order(:first_name, :last_name)

    # If lead_id is provided, populate customer with lead data
    if params[:lead_id].present?
      @lead = Lead.find(params[:lead_id])

      # Basic information mapping
      # customer_type assignment removed - field doesn't exist in customers table
      @customer.email = @lead.email
      @customer.mobile = @lead.contact_number
      @customer.address = @lead.address
      @customer.city = @lead.city
      @customer.state = @lead.state

      # Individual customer mapping
      if @lead.individual?
        @customer.first_name = @lead.first_name
        @customer.middle_name = @lead.middle_name
        @customer.last_name = @lead.last_name
        @customer.birth_date = @lead.birth_date
        @customer.birth_place = @lead.birth_place
        @customer.gender = @lead.gender

        # Map height and weight with correct field names
        @customer.height_feet = @lead.height_feet.presence || @lead.height
        @customer.weight_kg = @lead.weight_kg.presence || @lead.weight

        @customer.education = @lead.education
        @customer.marital_status = @lead.marital_status
        @customer.business_job = @lead.business_job

        # Map business/job name with fallbacks
        @customer.business_name = @lead.business_name.presence || @lead.business_job_name
        @customer.job_name = @lead.job_name.presence || @lead.business_job_name
        @customer.occupation = @lead.occupation

        @customer.type_of_duty = @lead.type_of_duty.presence || @lead.duty_type
        @customer.annual_income = @lead.annual_income

        # Map PAN to both fields for compatibility
        @customer.pan_no = @lead.pan_no
        @customer.pan_number = @lead.pan_no

        @customer.additional_information = @lead.additional_information
      # Corporate customer mapping
      elsif @lead.corporate?
        @customer.company_name = @lead.company_name

        # Map PAN to both fields for compatibility
        @customer.pan_no = @lead.pan_no
        @customer.pan_number = @lead.pan_no

        # Map GST to both fields for compatibility
        @customer.gst_no = @lead.gst_no
        @customer.gst_number = @lead.gst_no

        @customer.annual_income = @lead.annual_income
        @customer.additional_information = @lead.additional_information
      else
        # Fallback for legacy data
        @customer.first_name = extract_first_name(@lead.name)
        @customer.last_name = extract_last_name(@lead.name)
      end

      # Auto-populate affiliate from lead
      if @lead.affiliate_id.present?
        @customer.sub_agent_id = @lead.affiliate_id
      end

      # Calculate age if birth_date is present
      if @customer.birth_date.present?
        @customer.age = calculate_age(@customer.birth_date)
      end

      # Store lead reference for future conversion
      @customer.lead_id = @lead.lead_id
    end
  end

  # GET /admin/customers/1/edit
  def edit
    @sub_agents = SubAgent.active.order(:first_name, :last_name)
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

          # Create User account - auto-generate password if not provided
          should_create_user = user_enter_password == '1' ||
                             (@customer.email.present? && password.blank?)

          if should_create_user
            if password.present? && password_confirmation.present?
              # Use provided password
              if password == password_confirmation
                generated_password = password
                User.create!(
                  first_name: @customer.first_name,
                  last_name: @customer.last_name || @customer.company_name,
                  email: @customer.email,
                  mobile: @customer.mobile,
                  password: generated_password,
                  password_confirmation: generated_password,
                  original_password: generated_password,
                  user_type: 'customer',
                  status: true
                )
                redirect_to product_selection_admin_customer_path(@customer), notice: 'Customer and login account created successfully.'
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
                last_name: @customer.last_name || @customer.company_name,
                email: @customer.email,
                mobile: @customer.mobile,
                password: generated_password,
                password_confirmation: generated_password,
                original_password: generated_password,
                user_type: 'customer',
                status: true
              )
              # Store generated password in flash for display (in production, send via email/SMS)
              flash[:generated_password] = generated_password
              redirect_to product_selection_admin_customer_path(@customer),
                         notice: "Customer created successfully. Auto-generated password: #{generated_password}"
            end
          else
            redirect_to product_selection_admin_customer_path(@customer), notice: 'Customer was successfully created.'
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
      @sub_agents = SubAgent.active.order(:first_name, :last_name)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/customers/1
  def destroy
    if @customer.policies.exists?
      redirect_to admin_customers_path, alert: 'Cannot delete customer with existing policies.'
    else
      @customer.destroy
      redirect_to admin_customers_path, notice: 'Customer was successfully deleted.'
    end
  end

  # PATCH /admin/customers/1/toggle_status
  def toggle_status
    @customer.update(status: !@customer.status)
    status_text = @customer.status? ? 'activated' : 'deactivated'
    redirect_to admin_customers_path, notice: "Customer was successfully #{status_text}."
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
    # Generate password in format: first 4 letters of name + @ + 4-digit year from DOB
    # Example: PRAMOD with DOB 26/02/1996 becomes PRAM@1996

    # Get first name - use first_name from customer
    first_name = @customer.first_name.to_s.strip.upcase

    # Get first 4 characters of name, pad with 'X' if less than 4 characters
    name_part = first_name[0..3].ljust(4, 'X')

    # Get birth year from birth_date
    if @customer.birth_date.present?
      year_part = @customer.birth_date.year.to_s
    else
      # Default to current year if no birth date
      year_part = Date.current.year.to_s
    end

    "#{name_part}@#{year_part}"
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :first_name, :last_name, :email, :mobile,
      :address, :state, :city, :pincode, :pan_no, :pan_number, :gst_no, :gst_number, :birth_date,
      :gender, :occupation, :job_name, :annual_income, :nominee_name, :nominee_relation,
      :nominee_date_of_birth, :status, :birth_place, :height_feet, :weight_kg, :education,
      :marital_status, :business_job, :business_name, :type_of_duty, :additional_information, :additional_info,
      :added_by, :sub_agent_id, :age, :longitude, :latitude, :whatsapp_number, :auto_generated_password,
      :location_obtained_at, :location_accuracy, :password, :password_confirmation,
      :personal_image, :house_image, profile_image: [],
      documents_attributes: [:id, :document_type, :file, :_destroy],
      uploaded_documents_attributes: [:id, :title, :description, :document_type, :file, :uploaded_by, :_destroy],
      family_members_attributes: [
        :id, :first_name, :middle_name, :last_name, :birth_date, :age, :height_feet, :weight_kg,
        :gender, :relationship, :pan_no, :mobile, :additional_information, :_destroy,
        documents_attributes: [:id, :document_type, :file, :_destroy]
      ],
      corporate_members_attributes: [
        :id, :company_name, :mobile, :email, :state, :city, :address, :annual_income,
        :pan_no, :gst_no, :additional_information, :_destroy,
        documents_attributes: [:id, :document_type, :file, :_destroy]
      ]
    )
  end

  def generate_customers_csv(customers)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << %w[
        ID FirstName LastName Email Mobile
        Address State City Pincode BirthDate Gender Height Weight
        Education MaritalStatus Occupation JobName TypeOfDuty AnnualIncome
        PANNumber GSTNumber BirthPlace NomineeName NomineeRelation
        NomineeDOB Status AddedBy CreatedAt
      ]

      customers.find_each do |customer|
        csv << [
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