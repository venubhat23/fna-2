class Admin::LifeInsurancesController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_life_insurance, only: [:show, :edit, :update, :destroy, :remove_rider, :commission_details]

  # GET /admin/insurance/life
  def index
    @life_insurances = LifeInsurance.includes(:customer, :sub_agent, :agency_code, :broker)

    # Tab-based filtering for DrWise vs Non-DrWise policies
    @current_tab = params[:tab] || 'drwise'

    case @current_tab
    when 'drwise'
      # DrWise policies: Admin added policies (is_admin_added: true AND others false)
      @life_insurances = @life_insurances.where(
        is_admin_added: true,
        is_customer_added: false,
        is_agent_added: false
      )
    when 'non_drwise'
      # Non-DrWise policies: Customer or Agent added policies
      @life_insurances = @life_insurances.where(
        '(is_customer_added = ? AND is_admin_added = ? AND is_agent_added = ?) OR (is_agent_added = ? AND is_customer_added = ? AND is_admin_added = ?)',
        true, false, false, true, false, false
      )
    end

    # Search functionality (within current tab)
    if params[:search].present?
      @life_insurances = @life_insurances.search_life_policies(params[:search])
    end

    # Filter by payment mode
    if params[:payment_mode].present?
      @life_insurances = @life_insurances.where(payment_mode: params[:payment_mode])
    end

    # Filter by status
    case params[:status]
    when 'active'
      @life_insurances = @life_insurances.active
    when 'expired'
      @life_insurances = @life_insurances.expired
    when 'expiring_soon'
      @life_insurances = @life_insurances.expiring_soon
    end

    # Filter by policy type
    if params[:policy_type].present?
      @life_insurances = @life_insurances.where(policy_type: params[:policy_type])
    end

    # Filter by insurance company
    if params[:company].present?
      @life_insurances = @life_insurances.where(insurance_company_name: params[:company])
    end

    # Calculate statistics for current tab (before pagination)
    calculate_tab_statistics

    @life_insurances = paginate_records(@life_insurances.order(created_at: :desc))
  end

  # GET /admin/insurance/life/1
  def show
  end

  # GET /admin/insurance/life/new
  def new
    @life_insurance = LifeInsurance.new
    set_form_data
  end

  # GET /admin/insurance/life/1/edit
  def edit
    set_form_data
  end

  # POST /admin/insurance/life
  def create
    processed_params = process_broker_params(life_insurance_params)
    @life_insurance = LifeInsurance.new(processed_params)

    # Set admin tracking fields for policies created from admin panel
    @life_insurance.policy_added_by_admin = true
    @life_insurance.is_admin_added = true
    @life_insurance.is_customer_added = false
    @life_insurance.is_agent_added = false

    set_distributor_from_affiliate(@life_insurance)

    begin
      if @life_insurance.save
        redirect_to admin_life_insurances_path,
                    notice: 'Life insurance policy was successfully created.'
      else
        set_form_data
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique => e
      if e.message.include?('policy_number')
        @life_insurance.errors.add(:policy_number, 'has already been taken')
      else
        @life_insurance.errors.add(:base, 'A record with similar details already exists')
      end
      set_form_data
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/insurance/life/1
  def update
    processed_params = process_broker_params(life_insurance_params)
    @life_insurance.assign_attributes(processed_params)
    set_distributor_from_affiliate(@life_insurance)

    begin
      if @life_insurance.save
        redirect_to admin_life_insurances_path,
                    notice: 'Life insurance policy was successfully updated.'
      else
        set_form_data
        render :edit, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique => e
      if e.message.include?('policy_number')
        @life_insurance.errors.add(:policy_number, 'has already been taken')
      else
        @life_insurance.errors.add(:base, 'A record with similar details already exists')
      end
      set_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/insurance/life/1
  def destroy
    @life_insurance.destroy
    redirect_to admin_life_insurances_path,
                notice: 'Life insurance policy was successfully deleted.'
  end

  # GET /admin/insurance/life/policy_holder_options
  def policy_holder_options
    customer = Customer.find(params[:customer_id]) if params[:customer_id].present?
    options = [{ label: 'Self', value: 'Self' }]

    if customer&.family_members&.any?
      customer.family_members.each do |member|
        options << {
          label: member.full_name,
          value: member.id.to_s,
          relationship: member.relationship,
          age: member.age
        }
      end
    end

    render json: { options: options }
  end

  # PATCH /admin/insurance/life/1/remove_rider
  def remove_rider
    rider_type = params[:rider_type]

    case rider_type
    when 'term'
      @life_insurance.update(term_rider_amount: 0, term_rider_note: nil)
    when 'critical_illness'
      @life_insurance.update(critical_illness_rider_amount: 0, critical_illness_rider_note: nil)
    when 'accident'
      @life_insurance.update(accident_rider_amount: 0, accident_rider_note: nil)
    when 'pwb'
      @life_insurance.update(pwb_rider_amount: 0, pwb_rider_note: nil)
    when 'other'
      @life_insurance.update(other_rider_amount: 0, other_rider_note: nil)
    end

    redirect_to edit_admin_life_insurance_path(@life_insurance),
                notice: "#{rider_type.humanize} rider information removed successfully."
  end

  # GET /admin/insurance/life/1/commission_details
  def commission_details
    # This will render the commission details view
  end

  # API endpoint for getting brokers by insurance company
  def brokers_by_company
    company_name = params[:company_name]
    brokers = if company_name.present?
                # First get insurance_company by name, then get brokers
                insurance_company = InsuranceCompany.find_by(name: company_name)
                if insurance_company
                  Broker.where(insurance_company: insurance_company).active.order(:name)
                else
                  Broker.none
                end
              else
                Broker.none
              end

    render json: {
      brokers: brokers.map { |b| { id: b.id, name: b.name } }
    }
  end

  # API endpoint for getting agency codes by broker
  def agency_codes_by_broker
    broker_id = params[:broker_id]
    agency_codes = if broker_id.present?
                     AgencyCode.where(broker_id: broker_id, insurance_type: 'Life').order(:code)
                   else
                     AgencyCode.none
                   end

    render json: {
      agency_codes: agency_codes.map { |a| { id: a.id, name: "#{a.company_name} - #{a.code}" } }
    }
  end

  # API endpoint for getting all agency codes (for Direct selection)
  def all_agency_codes
    agency_codes = AgencyCode.where(insurance_type: 'Life').order(:code)

    render json: {
      agency_codes: agency_codes.map { |a| { id: a.id, name: "#{a.company_name} - #{a.code}" } }
    }
  end

  # API endpoint for getting all brokers (for Broking selection)
  def all_brokers
    brokers = Broker.active.order(:name)

    render json: {
      brokers: brokers.map { |b| { id: b.id, name: b.name } }
    }
  end

  private

  def set_life_insurance
    @life_insurance = LifeInsurance.find(params[:id])
  end

  def set_form_data
    @customers = Customer.active.order(:first_name, :last_name, :company_name)
    @sub_agents = SubAgent.active.order(:first_name, :last_name)
    @distributors = Distributor.active.order(:first_name, :last_name)
    @investors = Investor.active.order(:first_name, :last_name)

    # For cascading dropdowns, load empty or filtered data based on existing selections
    if @life_insurance&.insurance_company_name.present?
      # If editing and company is selected, load relevant brokers
      insurance_company = InsuranceCompany.find_by(name: @life_insurance.insurance_company_name)
      @brokers = insurance_company ? Broker.where(insurance_company: insurance_company).active.order(:name) : []

      if @life_insurance.broker_id.present?
        # If editing and broker is selected, load relevant agency codes
        @agency_codes = AgencyCode.where(broker_id: @life_insurance.broker_id, insurance_type: 'Life').order(:code)
      else
        @agency_codes = []
      end
    else
      # For new records or when no company is selected, start with empty dependent dropdowns
      @brokers = []
      @agency_codes = []
    end

    @insurance_companies = InsuranceCompanyHelper.company_names
    @policy_types = LifeInsurance::POLICY_TYPES
    @payment_modes = LifeInsurance::PAYMENT_MODES
    @relationships = LifeInsurance::RELATIONSHIPS
    @account_types = LifeInsurance::ACCOUNT_TYPES
    @document_types = LifeInsurance::DOCUMENT_TYPES
  end

  def process_broker_params(params)
    # Handle agency_code_id when it contains broker_X format
    if params[:agency_code_id].present? && params[:agency_code_id].start_with?('broker_')
      # Extract broker ID from broker_X format
      broker_id = params[:agency_code_id].gsub('broker_', '').to_i

      # Set broker_id and clear agency_code_id for broking type
      if broker_id > 0
        params[:broker_id] = broker_id
        params[:agency_code_id] = nil
      end
    end

    params
  end

  def life_insurance_params
    params.require(:life_insurance).permit(
      :customer_id, :sub_agent_id, :distributor_id, :investor_id, :agency_code_id, :broker_id, :broker_code_type,
      :policy_holder, :insured_name, :insurance_company_name, :policy_type,
      :payment_mode, :policy_number, :policy_booking_date, :policy_start_date,
      :policy_end_date, :risk_start_date, :policy_term, :premium_payment_term,
      :plan_name, :sum_insured, :net_premium, :first_year_gst_percentage,
      :second_year_gst_percentage, :third_year_gst_percentage, :total_premium,
      :term_rider_amount, :term_rider_note, :critical_illness_rider_amount,
      :critical_illness_rider_note, :accident_rider_amount, :accident_rider_note,
      :pwb_rider_amount, :pwb_rider_note, :other_rider_amount, :other_rider_note,
      :nominee_name, :nominee_relationship, :nominee_age, :bank_name,
      :account_type, :account_number, :ifsc_code, :account_holder_name,
      :reference_by_name, :broker_name, :bonus, :fund, :extra_note,
      :main_agent_commission_percentage, :commission_amount, :tds_percentage,
      :tds_amount, :after_tds_value, :installment_autopay_start_date,
      :installment_autopay_end_date, :active,
      # New commission fields - All commission details
      :sub_agent_commission_percentage, :sub_agent_commission_amount, :sub_agent_tds_percentage, :sub_agent_tds_amount, :sub_agent_after_tds_value,
      :distributor_commission_percentage, :distributor_commission_amount, :distributor_tds_percentage, :distributor_tds_amount, :distributor_after_tds_value,
      :ambassador_commission_percentage, :ambassador_commission_amount, :ambassador_tds_percentage, :ambassador_tds_amount, :ambassador_after_tds_value,
      :investor_commission_percentage, :investor_commission_amount, :investor_tds_percentage, :investor_tds_amount, :investor_after_tds_value,
      :main_income_percentage, :main_income_amount,
      # Company expenses and profit fields
      :company_expenses_percentage, :total_distribution_percentage,
      :profit_percentage, :profit_amount,
      policy_documents: [], documents: [],
      uploaded_documents_attributes: [:id, :title, :description, :document_type, :file, :uploaded_by, :_destroy]
    )
  end

  def set_distributor_from_affiliate(insurance_record)
    # If affiliate is selected but distributor is not set, auto-assign distributor
    if insurance_record.sub_agent_id.present? && insurance_record.distributor_id.blank?
      sub_agent = SubAgent.find(insurance_record.sub_agent_id)

      # Use direct distributor relationship first, then fall back to assignment
      distributor_id = sub_agent.distributor_id || sub_agent.assigned_distributor&.id

      insurance_record.distributor_id = distributor_id if distributor_id.present?
    end
  rescue StandardError => e
    # Log error but don't fail the form submission
    Rails.logger.error "Failed to set distributor from affiliate: #{e.message}"
  end

  def calculate_tab_statistics
    # Calculate statistics for all DrWise policies
    drwise_policies = LifeInsurance.where(
      is_admin_added: true,
      is_customer_added: false,
      is_agent_added: false
    )

    @drwise_count = drwise_policies.count
    @drwise_premium = drwise_policies.sum(:total_premium) || 0
    @drwise_coverage = drwise_policies.sum(:sum_insured) || 0

    # Calculate statistics for all Non-DrWise policies
    non_drwise_policies = LifeInsurance.where(
      '(is_customer_added = ? AND is_admin_added = ? AND is_agent_added = ?) OR (is_agent_added = ? AND is_customer_added = ? AND is_admin_added = ?)',
      true, false, false, true, false, false
    )

    @non_drwise_count = non_drwise_policies.count
    @non_drwise_premium = non_drwise_policies.sum(:total_premium) || 0
    @non_drwise_coverage = non_drwise_policies.sum(:sum_insured) || 0

    # Set current tab statistics
    if @current_tab == 'drwise'
      @total_policies_count = @drwise_count
      @total_premium_amount = @drwise_premium
      @total_coverage_amount = @drwise_coverage
      @covered_lives_count = drwise_policies.joins(:customer).distinct.count('customers.id')
    else
      @total_policies_count = @non_drwise_count
      @total_premium_amount = @non_drwise_premium
      @total_coverage_amount = @non_drwise_coverage
      @covered_lives_count = non_drwise_policies.joins(:customer).distinct.count('customers.id')
    end
  end
end