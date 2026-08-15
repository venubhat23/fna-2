class Api::V1::HealthInsurancesController < Api::V1::ApplicationController
  before_action :set_health_insurance, only: [:show, :update, :destroy]

  # GET /api/v1/health_insurances
  def index
    @health_insurances = HealthInsurance.includes(:customer, :sub_agent, :agency_code, :broker, :health_insurance_members)

    # Search functionality
    if params[:search].present?
      @health_insurances = @health_insurances.search_health_policies(params[:search])
    end

    # Filter by status
    case params[:status]
    when 'active'
      @health_insurances = @health_insurances.active
    when 'expired'
      @health_insurances = @health_insurances.expired
    when 'expiring_soon'
      @health_insurances = @health_insurances.expiring_soon
    end

    # Filter by insurance type
    if params[:insurance_type].present?
      @health_insurances = @health_insurances.where(insurance_type: params[:insurance_type])
    end

    # Filter by insurance company
    if params[:company].present?
      @health_insurances = @health_insurances.where(insurance_company_name: params[:company])
    end

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      @health_insurances = @health_insurances.where(
        policy_start_date: Date.parse(params[:start_date])..Date.parse(params[:end_date])
      )
    end

    # Count the filtered scope before limit/offset are applied - Relation#count
    # includes LIMIT/OFFSET in its SQL, so counting after pagination was applied
    # returned at most the page size (never the real total) and issued 2 queries.
    limit = (params[:limit] || 20).to_i
    total_count = @health_insurances.count

    # Pagination
    @health_insurances = @health_insurances.order(created_at: :desc)
    @health_insurances = @health_insurances.limit(limit)
    @health_insurances = @health_insurances.offset(params[:offset] || 0)

    render json: {
      success: true,
      data: @health_insurances.map { |policy| policy_json(policy) },
      meta: {
        total_count: total_count,
        current_page: (params[:offset].to_i / limit) + 1,
        total_pages: (total_count / limit.to_f).ceil
      }
    }
  end

  # GET /api/v1/health_insurances/:id
  def show
    render json: {
      success: true,
      data: policy_detail_json(@health_insurance)
    }
  end

  # POST /api/v1/health_insurances
  def create
    @health_insurance = HealthInsurance.new(health_insurance_params)

    if @health_insurance.save
      render json: {
        success: true,
        message: 'Health insurance policy created successfully',
        data: policy_detail_json(@health_insurance)
      }, status: :created
    else
      render json: {
        success: false,
        message: 'Failed to create health insurance policy',
        errors: @health_insurance.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/health_insurances/:id
  def update
    if @health_insurance.update(health_insurance_params)
      render json: {
        success: true,
        message: 'Health insurance policy updated successfully',
        data: policy_detail_json(@health_insurance)
      }
    else
      render json: {
        success: false,
        message: 'Failed to update health insurance policy',
        errors: @health_insurance.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/health_insurances/:id
  def destroy
    if @health_insurance.destroy
      render json: {
        success: true,
        message: 'Health insurance policy deleted successfully'
      }
    else
      render json: {
        success: false,
        message: 'Failed to delete health insurance policy'
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/health_insurances/statistics
  def statistics
    policies = HealthInsurance.all

    # Single aggregate query replaces 7 separate COUNT/SUM round trips.
    total_policies, active_policies, expired_policies, expiring_soon,
      total_premium, total_sum_insured, total_commission = policies.pluck(
      Arel.sql("COUNT(*)"),
      Arel.sql("COUNT(*) FILTER (WHERE policy_end_date >= CURRENT_DATE)"),
      Arel.sql("COUNT(*) FILTER (WHERE policy_end_date < CURRENT_DATE)"),
      Arel.sql("COUNT(*) FILTER (WHERE policy_end_date >= CURRENT_DATE AND policy_end_date <= CURRENT_DATE + INTERVAL '30 days')"),
      Arel.sql("COALESCE(SUM(total_premium), 0)"),
      Arel.sql("COALESCE(SUM(sum_insured), 0)"),
      Arel.sql("COALESCE(SUM(commission_amount), 0)")
    ).first

    render json: {
      success: true,
      data: {
        total_policies: total_policies,
        active_policies: active_policies,
        expired_policies: expired_policies,
        expiring_soon: expiring_soon,
        total_premium: total_premium.to_f,
        total_sum_insured: total_sum_insured.to_f,
        total_commission: total_commission.to_f,
        by_insurance_type: policies.group(:insurance_type).count,
        by_company: policies.group(:insurance_company_name).count,
        by_policy_type: policies.group(:policy_type).count,
        recent_policies: policies.order(created_at: :desc).limit(5).includes(:customer).map { |p| policy_json(p) }
      }
    }
  end

  # GET /api/v1/health_insurances/form_data
  def form_data
    # Customers/sub_agents/agency_codes/brokers barely change between requests but
    # were reloaded from the DB (4 queries) on every single form_data hit.
    db_backed_data = Rails.cache.fetch('api_v1_health_insurances_form_data', expires_in: 10.minutes) do
      {
        customers: Customer.active.order(:first_name, :last_name, :company_name).map do |c|
          {
            id: c.id,
            name: c.display_name,
            email: c.email,
            mobile: c.mobile,
            type: c.customer_type
          }
        end,
        sub_agents: SubAgent.active.order(:first_name, :last_name).map do |agent|
          {
            id: agent.id,
            name: agent.display_name,
            email: agent.email,
            mobile: agent.mobile
          }
        end,
        agency_codes: AgencyCode.where(insurance_type: 'Health').map do |code|
          {
            id: code.id,
            display_name: "#{code.company_name} - #{code.code}",
            company_name: code.company_name,
            code: code.code
          }
        end,
        brokers: Broker.active.order(:name).map do |broker|
          {
            id: broker.id,
            name: broker.name
          }
        end
      }
    end

    render json: {
      success: true,
      data: db_backed_data.merge(
        insurance_companies: InsuranceCompanyHelper.company_names,
        policy_types: HealthInsurance::POLICY_TYPES,
        insurance_types: HealthInsurance::INSURANCE_TYPES,
        payment_modes: HealthInsurance::PAYMENT_MODES,
        relationships: HealthInsuranceMember::RELATIONSHIPS
      )
    }
  end

  # GET /api/v1/health_insurances/policy_holder_options
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

    render json: {
      success: true,
      data: { options: options }
    }
  end

  private

  def set_health_insurance
    @health_insurance = HealthInsurance.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Health insurance policy not found'
    }, status: :not_found
  end

  def health_insurance_params
    params.require(:health_insurance).permit(
      :customer_id, :sub_agent_id, :agency_code_id, :broker_id,
      :policy_holder, :insurance_company_name, :policy_type, :insurance_type,
      :plan_name, :policy_number, :policy_booking_date, :policy_start_date,
      :policy_end_date, :policy_term, :payment_mode, :claim_process,
      :sum_insured, :net_premium, :gst_percentage, :total_premium,
      :main_agent_commission_percentage, :commission_amount, :tds_percentage,
      :tds_amount, :after_tds_value, :reference_by_name,
      health_insurance_members_attributes: [
        :id, :member_name, :age, :relationship, :sum_insured, :_destroy
      ]
    )
  end

  def policy_json(policy)
    {
      id: policy.id,
      policy_number: policy.policy_number,
      customer_name: policy.customer.display_name,
      customer_email: policy.customer.email,
      customer_mobile: policy.customer.mobile,
      insurance_company_name: policy.insurance_company_name,
      insurance_type: policy.insurance_type,
      policy_type: policy.policy_type,
      plan_name: policy.plan_name,
      sum_insured: policy.sum_insured,
      net_premium: policy.net_premium,
      total_premium: policy.total_premium,
      policy_start_date: policy.policy_start_date,
      policy_end_date: policy.policy_end_date,
      status: policy.active? ? 'active' : (policy.expired? ? 'expired' : 'pending'),
      days_until_expiry: policy.days_until_expiry,
      affiliate_name: policy.affiliate_name,
      created_at: policy.created_at,
      updated_at: policy.updated_at
    }
  end

  def policy_detail_json(policy)
    policy_json(policy).merge({
      policy_holder: policy.policy_holder,
      policy_booking_date: policy.policy_booking_date,
      policy_term: policy.policy_term,
      payment_mode: policy.payment_mode,
      claim_process: policy.claim_process,
      gst_percentage: policy.gst_percentage,
      main_agent_commission_percentage: policy.main_agent_commission_percentage,
      commission_amount: policy.commission_amount,
      tds_percentage: policy.tds_percentage,
      tds_amount: policy.tds_amount,
      after_tds_value: policy.after_tds_value,
      reference_by_name: policy.reference_by_name,
      customer: {
        id: policy.customer.id,
        name: policy.customer.display_name,
        email: policy.customer.email,
        mobile: policy.customer.mobile,
        type: policy.customer.customer_type
      },
      sub_agent: policy.sub_agent ? {
        id: policy.sub_agent.id,
        name: policy.sub_agent.display_name,
        email: policy.sub_agent.email,
        mobile: policy.sub_agent.mobile
      } : nil,
      agency_code: policy.agency_code ? {
        id: policy.agency_code.id,
        company_name: policy.agency_code.company_name,
        code: policy.agency_code.code
      } : nil,
      broker: policy.broker ? {
        id: policy.broker.id,
        name: policy.broker.name
      } : nil,
      family_members: policy.health_insurance_members.map do |member|
        {
          id: member.id,
          member_name: member.member_name,
          age: member.age,
          relationship: member.relationship,
          sum_insured: member.sum_insured
        }
      end,
      documents: policy.policy_documents.attached? ?
        policy.policy_documents.map { |doc| rails_blob_url(doc) } : [],
      additional_documents: policy.documents.attached? ?
        policy.documents.map { |doc| rails_blob_url(doc) } : []
    })
  end
end