class Admin::MotorInsurancesController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_motor_insurance, only: [:show, :edit, :update, :destroy]
  before_action :load_form_data, only: [:new, :edit, :create, :update]

  def index
    @motor_insurances = MotorInsurance.includes(:customer, :sub_agent, :agency_code, :broker)

    # Search functionality
    if params[:search].present?
      @motor_insurances = @motor_insurances.search_motor_policies(params[:search])
    end

    # Filter by status
    case params[:status]
    when 'active'
      @motor_insurances = @motor_insurances.active
    when 'expired'
      @motor_insurances = @motor_insurances.expired
    when 'expiring_soon'
      @motor_insurances = @motor_insurances.expiring_soon
    end

    # Filter by insurance type
    if params[:insurance_type].present?
      @motor_insurances = @motor_insurances.where(insurance_type: params[:insurance_type])
    end

    # Filter by policy type
    if params[:policy_type].present?
      @motor_insurances = @motor_insurances.where(policy_type: params[:policy_type])
    end

    # Filter by insurance company
    if params[:company].present?
      @motor_insurances = @motor_insurances.where(insurance_company_name: params[:company])
    end

    @motor_insurances = paginate_records(@motor_insurances.order(created_at: :desc))
  end

  def show
  end

  def new
    @motor_insurance = MotorInsurance.new(
      policy_booking_date: Date.current,
      policy_start_date: Date.current,
      policy_end_date: Date.current + 1.year,
      gst_percentage: 18.0,
      is_admin_added: true
    )
  end

  def edit
  end

  def create
    @motor_insurance = MotorInsurance.new(motor_insurance_params)

    # Set admin tracking fields for policies created from admin panel
    @motor_insurance.policy_added_by_admin = true
    @motor_insurance.is_admin_added = true
    @motor_insurance.is_customer_added = false
    @motor_insurance.is_agent_added = false

    set_distributor_from_affiliate(@motor_insurance)

    if @motor_insurance.save
      redirect_to admin_motor_insurance_path(@motor_insurance), notice: 'Motor insurance policy was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @motor_insurance.assign_attributes(motor_insurance_params)
    set_distributor_from_affiliate(@motor_insurance)

    if @motor_insurance.save
      redirect_to admin_motor_insurance_path(@motor_insurance), notice: 'Motor insurance policy was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @motor_insurance.destroy
    redirect_to admin_motor_insurances_path, notice: 'Motor insurance policy was successfully deleted.'
  end

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

  def set_motor_insurance
    @motor_insurance = MotorInsurance.find(params[:id])
  end

  def load_form_data
    @customers = Customer.active.order(:first_name, :last_name)
    @sub_agents = SubAgent.active.order(:first_name, :last_name)
    @distributors = Distributor.active.order(:first_name, :last_name)
    @investors = Investor.active.order(:first_name, :last_name)
    @agency_codes = AgencyCode.all.order(:code)
    @brokers = Broker.active.order(:name)
    @insurance_companies = MotorInsurance.insurance_company_names
    @vehicle_types = MotorInsurance::VEHICLE_TYPES
    @class_of_vehicles = MotorInsurance::CLASS_OF_VEHICLES
    @insurance_types = MotorInsurance::INSURANCE_TYPES
    @policy_types = MotorInsurance::POLICY_TYPES
    @payout_options = MotorInsurance::PAYOUT_OPTIONS
  end

  def motor_insurance_params
    params.require(:motor_insurance).permit(
      # Client & Agent Details
      :customer_id, :policy_holder, :sub_agent_id, :distributor_id, :investor_id, :reference_by_name,

      # Policy Details
      :insurance_company_name, :agency_code_id, :broker_id, :vehicle_type,
      :class_of_vehicle, :insurance_type, :policy_type, :policy_booking_date,
      :policy_start_date, :policy_end_date, :policy_number, :registration_number,
      :registration_date, :tp_premium, :net_premium, :gst_percentage, :total_premium,

      # Vehicle Details
      :vehicle_idv, :cng_idv, :total_idv, :engine_number, :chassis_number,
      :mfy, :make, :model, :variant, :seating_capacity, :ncb, :discount_loading_percent,

      # Advance Details
      :broker_name, :previous_policy_number, :extra_note,

      # Commission Details
      :payout_od, :payout_tp, :payout_net, :main_agent_commission_percent,
      :main_agent_commission_amount, :main_agent_tds_percent, :main_agent_tds_amount,
      :after_tds_value,

      # Enhanced Commission Structure
      :main_agent_commission_percentage, :commission_amount, :tds_percentage, :tds_amount,
      :sub_agent_commission_percentage, :sub_agent_commission_amount, :sub_agent_tds_percentage,
      :sub_agent_tds_amount, :sub_agent_after_tds_value,
      :distributor_commission_percentage, :distributor_commission_amount, :distributor_tds_percentage,
      :distributor_tds_amount, :distributor_after_tds_value,
      :investor_commission_percentage, :investor_commission_amount, :investor_tds_percentage,
      :investor_tds_amount, :investor_after_tds_value,
      :ambassador_commission_percentage, :ambassador_commission_amount, :ambassador_tds_percentage,
      :ambassador_tds_amount, :ambassador_after_tds_value,
      :total_distribution_percentage, :company_expenses_percentage, :profit_percentage, :profit_amount,

      # Legal Liability & Optional Covers
      :legal_liability, :electrical_accessories, :non_electrical_accessories,
      :zero_depreciation, :roadside_assistance, :engine_protector, :key_replacement,
      :return_to_invoice, :consumable_cover, :personal_accident_cover, :financier
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