class Admin::AgencyCodesController < Admin::ApplicationController
  include InsuranceCompanyMethods

  before_action :set_agency_code, only: [:show, :edit, :update, :destroy]

  # GET /admin/agency_codes
  def index
    @agency_codes = AgencyCode.all

    # Apply search filter
    if params[:search].present?
      @agency_codes = @agency_codes.search(params[:search])
    end

    # Apply company filter
    if params[:company].present?
      @agency_codes = @agency_codes.by_company(params[:company])
    end

    # Apply insurance type filter
    if params[:insurance_type].present?
      @agency_codes = @agency_codes.by_insurance_type(params[:insurance_type])
    end

    respond_to do |format|
      format.html do
        # Get total count before pagination for display purposes
        @total_filtered_count = @agency_codes.count

        # Apply pagination (10 records per page)
        @agency_codes = @agency_codes.order(created_at: :desc).page(params[:page]).per(10)

        # For filters
        @insurance_companies = insurance_companies_list

        # Statistics (use unfiltered counts for stats cards)
        @total_codes = AgencyCode.count
        @health_codes = AgencyCode.where(insurance_type: 'Health').count
        @motor_codes = AgencyCode.where(insurance_type: 'Motor').count
        @life_codes = AgencyCode.where(insurance_type: 'Life').count
      end

      format.json do
        # For JSON requests, return all matching records without pagination
        @agency_codes = @agency_codes.order(:agent_name, :code)
        render json: @agency_codes.map do |agency_code|
          {
            id: agency_code.id,
            agent_name: agency_code.agent_name,
            code: agency_code.code,
            company_name: agency_code.company_name,
            insurance_type: agency_code.insurance_type,
            broker_id: agency_code.broker_id
          }
        end
      end
    end
  end

  # GET /admin/agency_codes/1
  def show
  end

  # GET /admin/agency_codes/new
  def new
    @agency_code = AgencyCode.new
    @insurance_companies = insurance_companies_list
    @insurance_types = ['Health', 'Motor', 'Life', 'General', 'Other']
    @brokers = Broker.active.order(:name)
  end

  # GET /admin/agency_codes/1/edit
  def edit
    @insurance_companies = insurance_companies_list
    @insurance_types = ['Health', 'Motor', 'Life', 'General', 'Other']
    @brokers = Broker.active.order(:name)
  end

  # POST /admin/agency_codes
  def create
    @agency_code = AgencyCode.new(agency_code_params)

    if @agency_code.save
      redirect_to admin_agency_codes_path, notice: 'Agency code was successfully created.'
    else
      @insurance_companies = insurance_companies_list
      @insurance_types = ['Health', 'Motor', 'Life', 'General', 'Other']
      @brokers = Broker.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/agency_codes/1
  def update
    if @agency_code.update(agency_code_params)
      redirect_to admin_agency_codes_path, notice: 'Agency code was successfully updated.'
    else
      @insurance_companies = insurance_companies_list
      @insurance_types = ['Health', 'Motor', 'Life', 'General', 'Other']
      @brokers = Broker.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/agency_codes/1
  def destroy
    @agency_code.destroy
    redirect_to admin_agency_codes_path, notice: 'Agency code was successfully deleted.'
  end

  # GET /admin/agency_codes/search - For AJAX search
  def search
    @agency_codes = AgencyCode.all

    if params[:search].present?
      @agency_codes = @agency_codes.search(params[:search])
    end

    if params[:company].present?
      @agency_codes = @agency_codes.by_company(params[:company])
    end

    if params[:insurance_type].present?
      @agency_codes = @agency_codes.by_insurance_type(params[:insurance_type])
    end

    # Get total count before pagination for display purposes
    @total_filtered_count = @agency_codes.count

    # Apply pagination (10 records per page)
    @agency_codes = @agency_codes.order(created_at: :desc).page(params[:page]).per(10)

    render partial: 'agency_codes_table', locals: { agency_codes: @agency_codes, total_filtered_count: @total_filtered_count }
  end

  # GET /admin/agency_codes/brokers_for_direct - API endpoint for fetching all brokers when Direct is selected
  def brokers_for_direct
    # Get all active brokers for direct business
    @brokers = Broker.active.order(:name)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          brokers: @brokers.map { |broker| { id: broker.id, name: broker.name } }
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching brokers: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  # GET /admin/agency_codes/all_agents - API endpoint for fetching all agent names when Direct is selected
  def all_agents
    insurance_type = params[:insurance_type] || 'Life'

    # Get all unique agents for the insurance type (PostgreSQL compatible)
    @agency_codes = AgencyCode.where(insurance_type: insurance_type)
                             .select('agent_name, MIN(id) as id, MIN(code) as code, MIN(company_name) as company_name')
                             .group(:agent_name)
                             .order(:agent_name)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          agents: @agency_codes.map do |code|
            {
              id: code.id,
              agent_name: code.agent_name,
              code: code.code,
              company_name: code.company_name,
              display_name: "#{code.agent_name} - #{code.code}"
            }
          end
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching agents: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  # GET /admin/agency_codes/companies_for_agent - API endpoint for fetching companies for selected agent
  def companies_for_agent
    agent_name = params[:agent_name]
    insurance_type = params[:insurance_type] || 'Life'

    if agent_name.present?
      # Get all companies for this agent and insurance type (PostgreSQL compatible)
      @agency_codes = AgencyCode.where(agent_name: agent_name, insurance_type: insurance_type)
                               .select('company_name, MIN(id) as id')
                               .group(:company_name)
                               .order(:company_name)
    else
      @agency_codes = AgencyCode.none
    end

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          companies: @agency_codes.map do |code|
            {
              id: code.id,
              company_name: code.company_name
            }
          end
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching companies: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  # GET /admin/agency_codes/all_brokers - API endpoint for fetching all brokers when Broking is selected
  def all_brokers
    # Get all active brokers
    @brokers = Broker.active.order(:name)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          brokers: @brokers.map do |broker|
            {
              id: broker.id,
              name: broker.name
            }
          end
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching brokers: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  # GET /admin/agency_codes/all_codes - API endpoint for fetching all unique codes when Direct is selected
  def all_codes
    insurance_type = params[:insurance_type] || 'Life'

    # Get all unique codes for the insurance type
    @agency_codes = AgencyCode.where(insurance_type: insurance_type)
                             .select('code, MIN(id) as id')
                             .where.not(code: [nil, ''])
                             .group(:code)
                             .order(:code)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          codes: @agency_codes.map do |code_record|
            {
              id: code_record.id,
              code: code_record.code
            }
          end
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching codes: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  # GET /admin/agency_codes/agents_for_code - API endpoint for fetching agents for selected code
  def agents_for_code
    code = params[:code]
    insurance_type = params[:insurance_type] || 'Life'

    if code.present?
      # Get all agents for this code and insurance type
      @agency_codes = AgencyCode.where(code: code, insurance_type: insurance_type)
                               .select('agent_name, MIN(id) as id, code, company_name')
                               .group(:agent_name, :code, :company_name)
                               .order(:agent_name)
    else
      @agency_codes = AgencyCode.none
    end

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          agents: @agency_codes.map do |code_record|
            {
              id: code_record.id,
              agent_name: code_record.agent_name,
              code: code_record.code,
              company_name: code_record.company_name,
              display_name: "#{code_record.agent_name} - #{code_record.code}"
            }
          end
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching agents for code: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  # GET /admin/agency_codes/companies_for_broker - API endpoint for fetching companies for selected broker
  def companies_for_broker
    broker_id = params[:broker_id]

    if broker_id.present?
      # Get all companies for this broker
      broker = Broker.find_by(id: broker_id)

      # First try to get companies from agency codes linked to this broker
      agency_codes = AgencyCode.where(broker_id: broker_id)
                              .select('company_name')
                              .group(:company_name)
                              .order(:company_name)

      if agency_codes.any?
        companies = agency_codes.map(&:company_name)
      elsif broker&.respond_to?(:insurance_company) && broker.insurance_company
        # Fallback to broker's direct insurance company
        companies = [broker.insurance_company.name]
      else
        # If no specific associations found, return all available Life insurance companies
        # This ensures users can still select companies even if broker associations are not set up
        life_agency_codes = AgencyCode.where(insurance_type: 'Life')
                                     .select('company_name')
                                     .group(:company_name)
                                     .order(:company_name)
        companies = life_agency_codes.map(&:company_name)

        # If still no companies, fallback to hardcoded list
        if companies.empty?
          companies = [
            'ICICI Prudential Life Insurance Co Ltd',
            'HDFC Life Insurance Co Ltd',
            'SBI Life Insurance Co Ltd',
            'LIC of India',
            'Bajaj Allianz Life Insurance Co Ltd',
            'Max Life Insurance Co Ltd'
          ]
        end
      end
    else
      companies = []
    end

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          companies: companies.map.with_index do |company, index|
            {
              id: "broker_#{broker_id}_company_#{index}",
              company_name: company
            }
          end
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching companies for broker: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  # GET /admin/agency_codes/all_companies - API endpoint for fetching ALL companies for Broking mode
  def all_companies
    # Get all insurance companies from the InsuranceCompany table
    # This shows the same companies as in the admin sidebar
    companies = InsuranceCompany.order(:name).pluck(:name).compact.reject(&:blank?)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          companies: companies,
          count: companies.length
        }
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: {
          success: false,
          message: "Error fetching all companies: #{e.message}"
        }, status: :internal_server_error
      end
    end
  end

  private

  def set_agency_code
    @agency_code = AgencyCode.find(params[:id])
  end

  def agency_code_params
    params.require(:agency_code).permit(:insurance_type, :company_name, :agent_name, :code, :broker_id)
  end
end