class Admin::HealthInsurancesController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_health_insurance, only: [:show, :edit, :update, :destroy]
  before_action :load_form_data, only: [:new, :edit, :create, :update]

  def index
    @health_insurances = HealthInsurance.includes(:customer, :sub_agent, :agency_code, :broker)

    # Search functionality
    if params[:search].present?
      @health_insurances = @health_insurances.search_health_policies(params[:search])
    end

    @health_insurances = paginate_records(@health_insurances.order(created_at: :desc))
  end

  def show
  end

  def new
    @health_insurance = HealthInsurance.new
    @health_insurance.health_insurance_members.build
  end

  def edit
  end

  def create
    @health_insurance = HealthInsurance.new(health_insurance_params)

    # Set admin tracking fields for policies created from admin panel
    @health_insurance.policy_added_by_admin = true
    @health_insurance.is_admin_added = true
    @health_insurance.is_customer_added = false
    @health_insurance.is_agent_added = false

    set_distributor_from_affiliate(@health_insurance)

    if @health_insurance.save
      redirect_to admin_health_insurance_path(@health_insurance), notice: 'Health insurance policy was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @health_insurance.assign_attributes(health_insurance_params)
    set_distributor_from_affiliate(@health_insurance)

    if @health_insurance.save
      redirect_to admin_health_insurance_path(@health_insurance), notice: 'Health insurance policy was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @health_insurance.destroy
    redirect_to admin_health_insurances_path, notice: 'Health insurance policy was successfully deleted.'
  end

  # AJAX endpoint for getting policy holder options based on customer
  def policy_holder_options
    customer = Customer.find(params[:customer_id]) if params[:customer_id].present?
    options = [['Self', 'Self']]

    if customer&.family_members&.any?
      customer.family_members.each do |member|
        options << [member.full_name, member.id.to_s]
      end
    end

    render json: { options: options }
  end

  private

  def set_health_insurance
    @health_insurance = HealthInsurance.find(params[:id])
  end

  def load_form_data
    @customers = Customer.active.order(:first_name, :last_name, :company_name)
    @sub_agents = SubAgent.active.order(:first_name, :last_name)
    @distributors = Distributor.active.order(:first_name, :last_name)
    @investors = Investor.active.order(:first_name, :last_name)
    @agency_codes = AgencyCode.where(insurance_type: 'Health')
    @brokers = Broker.active.order(:name)
    @insurance_companies = InsuranceCompanyHelper.company_names
  end

  def health_insurance_params
    params.require(:health_insurance).permit(
      :customer_id, :sub_agent_id, :distributor_id, :investor_id, :agency_code_id, :broker_id,
      :policy_holder, :insurance_company_name, :policy_type, :insurance_type,
      :plan_name, :policy_number, :policy_booking_date, :policy_start_date,
      :policy_end_date, :policy_term, :payment_mode, :claim_process,
      :sum_insured, :net_premium, :gst_percentage, :total_premium,
      :main_agent_commission_percentage, :commission_amount, :tds_percentage,
      :tds_amount, :after_tds_value, :reference_by_name,
      :installment_autopay_start_date, :installment_autopay_end_date,
      health_insurance_members_attributes: [:id, :member_name, :age, :relationship, :sum_insured, :_destroy],
      documents: [], policy_documents: []
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
end