class Admin::SubAgentsController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_sub_agent, only: [:show, :edit, :update, :destroy, :documents]

  # GET /admin/sub_agents
  def index
    @sub_agents = SubAgent.all

    # Search functionality
    if params[:search].present?
      @sub_agents = @sub_agents.search_by_name_mobile_email(params[:search])
    end

    # Filter by status
    case params[:status]
    when 'active'
      @sub_agents = @sub_agents.active
    when 'inactive'
      @sub_agents = @sub_agents.inactive
    end

    # Get total count before pagination for display purposes
    @total_filtered_count = @sub_agents.count

    # Order and paginate using configurable pagination
    @sub_agents = paginate_records(@sub_agents.order(created_at: :desc))

    # Statistics
    @total_sub_agents = SubAgent.count
    @active_sub_agents = SubAgent.active.count
    @inactive_sub_agents = SubAgent.inactive.count
  end

  # GET /admin/sub_agents/1
  def show
    @documents = @sub_agent.sub_agent_documents.order(:created_at)
    @assigned_distributor = @sub_agent.assigned_distributor
    @distributor_assignment = @sub_agent.distributor_assignment

    # Get policies handled by this sub agent
    @health_policies = HealthInsurance.where(sub_agent_id: @sub_agent.id).includes(:customer).order(:created_at => :desc)
    @life_policies = LifeInsurance.where(sub_agent_id: @sub_agent.id).includes(:customer).order(:created_at => :desc)
    @motor_policies = MotorInsurance.where(sub_agent_id: @sub_agent.id).includes(:customer).order(:created_at => :desc)

    # Combine all policies for summary
    @all_policies = []

    @health_policies.each do |policy|
      @all_policies << {
        type: 'Health Insurance',
        policy: policy,
        policy_number: policy.policy_number,
        customer_name: policy.customer.display_name,
        company_name: policy.insurance_company_name,
        premium: policy.total_premium,
        start_date: policy.policy_start_date,
        end_date: policy.policy_end_date,
        status: policy.active? ? 'Active' : 'Expired',
        created_at: policy.created_at
      }
    end

    @life_policies.each do |policy|
      @all_policies << {
        type: 'Life Insurance',
        policy: policy,
        policy_number: policy.policy_number,
        customer_name: policy.customer.display_name,
        company_name: policy.insurance_company_name,
        premium: policy.total_premium,
        start_date: policy.policy_start_date,
        end_date: policy.policy_end_date,
        status: policy.active? ? 'Active' : 'Expired',
        created_at: policy.created_at
      }
    end

    @motor_policies.each do |policy|
      @all_policies << {
        type: 'Motor Insurance',
        policy: policy,
        policy_number: policy.policy_number,
        customer_name: policy.customer.display_name,
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

    # Get commission payouts for this sub agent (check both 'sub_agent' and 'affiliate')
    @commission_payouts = CommissionPayout.where(payout_to: ['sub_agent', 'affiliate'])
                                         .joins("LEFT JOIN health_insurances ON commission_payouts.policy_type = 'health' AND commission_payouts.policy_id = health_insurances.id
                                                 LEFT JOIN life_insurances ON commission_payouts.policy_type = 'life' AND commission_payouts.policy_id = life_insurances.id
                                                 LEFT JOIN motor_insurances ON commission_payouts.policy_type = 'motor' AND commission_payouts.policy_id = motor_insurances.id")
                                         .where(
                                           "(commission_payouts.policy_type = 'health' AND health_insurances.sub_agent_id = ?) OR
                                            (commission_payouts.policy_type = 'life' AND life_insurances.sub_agent_id = ?) OR
                                            (commission_payouts.policy_type = 'motor' AND motor_insurances.sub_agent_id = ?)",
                                           @sub_agent.id, @sub_agent.id, @sub_agent.id
                                         ).order(:payout_date => :desc)

    # Commission summary calculations
    @total_commission_earned = @commission_payouts.sum(:payout_amount)
    @paid_commission = @commission_payouts.paid.sum(:payout_amount)
    @pending_commission = @commission_payouts.pending.sum(:payout_amount)
    @processing_commission = @commission_payouts.processing.sum(:payout_amount)

    # Policy summary calculations
    @total_policies = @all_policies.count
    @active_policies = @all_policies.count { |p| p[:status] == 'Active' }
    @expired_policies = @all_policies.count { |p| p[:status] == 'Expired' }
    @total_premium_handled = @all_policies.sum { |p| p[:premium] || 0 }
  end

  # GET /admin/sub_agents/1/documents
  def documents
    @documents = @sub_agent.sub_agent_documents.order(:created_at)
    @uploaded_documents = @sub_agent.respond_to?(:uploaded_documents) ? @sub_agent.uploaded_documents.order(:created_at) : []
  end

  # GET /admin/sub_agents/new
  def new
    @sub_agent = SubAgent.new
    @sub_agent.sub_agent_documents.build
  end

  # GET /admin/sub_agents/1/edit
  def edit
    @sub_agent.sub_agent_documents.build if @sub_agent.sub_agent_documents.empty?
    @assigned_distributor = @sub_agent.assigned_distributor
    @distributor_assignment = @sub_agent.distributor_assignment
    @available_distributors = Distributor.active.order(:first_name, :last_name)

    # Get basic policy and commission summary for quick reference
    @total_policies = HealthInsurance.where(sub_agent_id: @sub_agent.id).count +
                     LifeInsurance.where(sub_agent_id: @sub_agent.id).count +
                     MotorInsurance.where(sub_agent_id: @sub_agent.id).count

    @total_commission = CommissionPayout.where(payout_to: ['sub_agent', 'affiliate'])
                                       .joins("LEFT JOIN health_insurances ON commission_payouts.policy_type = 'health' AND commission_payouts.policy_id = health_insurances.id
                                               LEFT JOIN life_insurances ON commission_payouts.policy_type = 'life' AND commission_payouts.policy_id = life_insurances.id
                                               LEFT JOIN motor_insurances ON commission_payouts.policy_type = 'motor' AND commission_payouts.policy_id = motor_insurances.id")
                                       .where(
                                         "(commission_payouts.policy_type = 'health' AND health_insurances.sub_agent_id = ?) OR
                                          (commission_payouts.policy_type = 'life' AND life_insurances.sub_agent_id = ?) OR
                                          (commission_payouts.policy_type = 'motor' AND motor_insurances.sub_agent_id = ?)",
                                         @sub_agent.id, @sub_agent.id, @sub_agent.id
                                       ).sum(:payout_amount)
  end

  # POST /admin/sub_agents
  def create
    @sub_agent = SubAgent.new(sub_agent_params)

    # Auto-generate password if not provided
    if @sub_agent.password.blank?
      generated_password = generate_affiliate_password
      @sub_agent.password = generated_password
      @sub_agent.password_confirmation = generated_password
    end

    if @sub_agent.save
      # Create User account for the sub agent
      create_user_account_for_sub_agent(@sub_agent)
      redirect_to admin_sub_agents_path, notice: 'Sub Agent was successfully created.'
    else
      @sub_agent.sub_agent_documents.build if @sub_agent.sub_agent_documents.empty?
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/sub_agents/1
  def update
    if @sub_agent.update(sub_agent_params)
      handle_distributor_assignment(@sub_agent, params[:assigned_distributor_id])
      redirect_to admin_sub_agents_path, notice: 'Sub Agent was successfully updated.'
    else
      @sub_agent.sub_agent_documents.build if @sub_agent.sub_agent_documents.empty?
      @assigned_distributor = @sub_agent.assigned_distributor
      @distributor_assignment = @sub_agent.distributor_assignment
      @available_distributors = Distributor.active.order(:first_name, :last_name)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/sub_agents/1
  def destroy
    # Check for relationships that would prevent deletion
    has_customers = @sub_agent.customers.exists?
    has_documents = @sub_agent.sub_agent_documents.exists?
    has_distributor_assignment = @sub_agent.distributor_assignment.present?

    # Check for insurance policies linked to this sub_agent
    has_health_policies = HealthInsurance.where(sub_agent_id: @sub_agent.id).exists? rescue false
    has_life_policies = LifeInsurance.where(sub_agent_id: @sub_agent.id).exists? rescue false
    has_motor_policies = MotorInsurance.where(sub_agent_id: @sub_agent.id).exists? rescue false
    has_other_policies = defined?(OtherInsurance) && OtherInsurance.where(sub_agent_id: @sub_agent.id).exists? rescue false

    # Check for leads linked to this affiliate
    has_leads = Lead.where(affiliate_id: @sub_agent.id).exists? rescue false

    # Check for corresponding User account
    has_user_account = User.where(email: @sub_agent.email).exists? rescue false

    if has_customers || has_health_policies || has_life_policies || has_motor_policies || has_other_policies || has_leads
      error_messages = []

      if has_customers
        customer_count = @sub_agent.customers.count
        error_messages << "#{customer_count} customer(s)"
      end

      policy_count = 0
      policy_count += HealthInsurance.where(sub_agent_id: @sub_agent.id).count rescue 0
      policy_count += LifeInsurance.where(sub_agent_id: @sub_agent.id).count rescue 0
      policy_count += MotorInsurance.where(sub_agent_id: @sub_agent.id).count rescue 0
      policy_count += OtherInsurance.where(sub_agent_id: @sub_agent.id).count rescue 0 if defined?(OtherInsurance)

      if policy_count > 0
        error_messages << "#{policy_count} insurance policy(ies)"
      end

      if has_leads
        lead_count = Lead.where(affiliate_id: @sub_agent.id).count rescue 0
        error_messages << "#{lead_count} lead(s)" if lead_count > 0
      end

      message = "Cannot delete affiliate with #{error_messages.join(', ')}. Please reassign or remove these records first."
      redirect_to admin_sub_agents_path, alert: message
    else
      begin
        # Delete associated records that can be safely removed
        if has_documents
          @sub_agent.sub_agent_documents.destroy_all
        end

        if has_distributor_assignment
          @sub_agent.distributor_assignment.destroy
        end

        # Delete corresponding User account if it exists
        if has_user_account
          user = User.find_by(email: @sub_agent.email)
          user&.destroy
        end

        # Now destroy the sub_agent
        @sub_agent.destroy!
        redirect_to admin_sub_agents_path, notice: 'Affiliate was successfully deleted.'
      rescue => e
        redirect_to admin_sub_agents_path,
                    alert: "Failed to delete affiliate: #{e.message}"
      end
    end
  end

  # PATCH /admin/sub_agents/1/toggle_status
  def toggle_status
    @sub_agent = SubAgent.find(params[:id])
    new_status = @sub_agent.active? ? :inactive : :active

    if @sub_agent.update(status: new_status)
      redirect_to admin_sub_agents_path, notice: "Sub Agent status updated to #{new_status}."
    else
      redirect_to admin_sub_agents_path, alert: 'Failed to update status.'
    end
  end

  # GET /admin/sub_agents/1/distributor
  def distributor
    @sub_agent = SubAgent.find(params[:id])

    # Check for direct distributor relationship first, then fall back to assignment
    distributor_id = @sub_agent.distributor_id || @sub_agent.assigned_distributor&.id

    render json: {
      distributor_id: distributor_id,
      distributor_name: distributor_id ? Distributor.find(distributor_id)&.display_name : nil
    }
  rescue ActiveRecord::RecordNotFound
    render json: { distributor_id: nil, distributor_name: nil }, status: :not_found
  end

  private

  def set_sub_agent
    @sub_agent = SubAgent.find(params[:id])
  end

  def sub_agent_params
    params.require(:sub_agent).permit(
      :first_name, :middle_name, :last_name, :mobile, :email, :password, :password_confirmation, :role_id,
      :state_id, :city_id, :birth_date, :gender, :pan_no, :gst_no,
      :company_name, :address, :bank_name, :account_no, :ifsc_code,
      :account_holder_name, :account_type, :upi_id, :status, :upload_main_document,
      sub_agent_documents_attributes: [:id, :document_type, :document_file, :_destroy],
      uploaded_documents_attributes: [:id, :title, :description, :document_type, :file, :uploaded_by, :_destroy]
    )
  end

  def generate_affiliate_password
    # Generate password similar to customer creation
    # Format: first 4 letters of name + @ + 4-digit year from DOB
    # Example: RAVI with DOB 15/03/1990 becomes RAVI@1990

    # Get first name - use first_name from sub_agent
    first_name = @sub_agent.first_name.to_s.strip.upcase

    # Get first 4 characters of name, pad with 'X' if less than 4 characters
    name_part = first_name[0..3].ljust(4, 'X')

    # Get birth year from birth_date
    if @sub_agent.birth_date.present?
      year_part = @sub_agent.birth_date.year.to_s
    else
      # Default to current year if no birth date
      year_part = Date.current.year.to_s
    end

    "#{name_part}@#{year_part}"
  end

  def create_user_account_for_sub_agent(sub_agent)
    # Create a corresponding User account for the sub_agent for system access
    User.create!(
      first_name: sub_agent.first_name,
      last_name: sub_agent.last_name,
      email: sub_agent.email,
      mobile: sub_agent.mobile,
      password: sub_agent.password,
      password_confirmation: sub_agent.password,
      user_type: 'sub_agent',
      role: 'sub_agent',
      status: true
    )
  rescue => e
    # Log error but don't fail the sub_agent creation
    Rails.logger.warn "Failed to create User account for SubAgent #{sub_agent.id}: #{e.message}"
  end

  def handle_distributor_assignment(sub_agent, assigned_distributor_id)
    # Remove existing assignment
    sub_agent.distributor_assignment&.destroy

    # Create new assignment if distributor is selected
    if assigned_distributor_id.present? && assigned_distributor_id != ''
      distributor = Distributor.find_by(id: assigned_distributor_id)
      if distributor
        DistributorAssignment.create!(
          distributor: distributor,
          sub_agent: sub_agent,
          assigned_at: Time.current
        )
      end
    end
  end
end