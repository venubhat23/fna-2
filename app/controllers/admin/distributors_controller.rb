class Admin::DistributorsController < Admin::ApplicationController
  include ConfigurablePagination
  before_action :set_distributor, only: [:show, :edit, :update, :destroy]

  # GET /admin/distributors
  def index
    @distributors = Distributor.all

    # Search functionality
    if params[:search].present?
      @distributors = @distributors.search_by_name_mobile_email(params[:search])
    end

    # Filter by status
    case params[:status]
    when 'active'
      @distributors = @distributors.active
    when 'inactive'
      @distributors = @distributors.inactive
    end

    # Get total count before pagination for display purposes
    @total_filtered_count = @distributors.count

    # Order and paginate using configurable pagination
    @distributors = paginate_records(@distributors.order(created_at: :desc))

    # Statistics
    @total_distributors = Distributor.count
    @active_distributors = Distributor.active.count
    @inactive_distributors = Distributor.inactive.count
  end

  # GET /admin/distributors/1
  def show
    @documents = @distributor.distributor_documents.order(:created_at)

    # Get assigned affiliates with their detailed information
    @assigned_affiliates = @distributor.assigned_sub_agents.includes(
      :distributor_assignment
    ).order('sub_agents.created_at DESC').to_a

    # Calculate statistics for each affiliate (batched to avoid N+1 across affiliates)
    @affiliate_stats = build_affiliate_stats(@assigned_affiliates)

    # Overall distributor statistics
    @distributor_stats = calculate_distributor_stats
  end

  # GET /admin/distributors/new
  def new
    @distributor = Distributor.new
    @distributor.role_id = 'distributor'
    @distributor.distributor_documents.build
  end

  # GET /admin/distributors/1/edit
  def edit
    @distributor.distributor_documents.build if @distributor.distributor_documents.empty?
  end

  # POST /admin/distributors
  def create
    @distributor = Distributor.new(distributor_params)
    @distributor.role_id = 'distributor'

    if @distributor.save
      handle_affiliate_assignments(@distributor, params[:distributor][:assigned_affiliate_ids])
      redirect_to admin_distributors_path, notice: 'Distributor was successfully created.'
    else
      @distributor.distributor_documents.build if @distributor.distributor_documents.empty?
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/distributors/1
  def update
    if @distributor.update(distributor_params)
      handle_affiliate_assignments(@distributor, params[:distributor][:assigned_affiliate_ids])
      redirect_to admin_distributors_path, notice: 'Distributor was successfully updated.'
    else
      @distributor.distributor_documents.build if @distributor.distributor_documents.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/distributors/1
  def destroy
    # Check for relationships that would prevent deletion
    has_assigned_affiliates = @distributor.assigned_sub_agents.exists?
    has_direct_affiliates = @distributor.sub_agents.exists?

    # Check for insurance policies directly linked to this distributor
    has_health_policies = HealthInsurance.where(distributor_id: @distributor.id).exists? rescue false
    has_life_policies = LifeInsurance.where(distributor_id: @distributor.id).exists? rescue false
    has_motor_policies = MotorInsurance.where(distributor_id: @distributor.id).exists? rescue false
    has_other_policies = defined?(OtherInsurance) && OtherInsurance.where(distributor_id: @distributor.id).exists? rescue false

    # Check for distributor payouts
    has_payouts = defined?(DistributorPayout) && DistributorPayout.where(distributor_id: @distributor.id).exists? rescue false

    if has_assigned_affiliates || has_direct_affiliates || has_health_policies || has_life_policies || has_motor_policies || has_other_policies || has_payouts
      error_messages = []

      if has_assigned_affiliates || has_direct_affiliates
        affiliate_count = @distributor.assigned_sub_agents.count + @distributor.sub_agents.count
        error_messages << "#{affiliate_count} assigned affiliate(s)"
      end

      policy_count = 0
      policy_count += HealthInsurance.where(distributor_id: @distributor.id).count rescue 0
      policy_count += LifeInsurance.where(distributor_id: @distributor.id).count rescue 0
      policy_count += MotorInsurance.where(distributor_id: @distributor.id).count rescue 0
      policy_count += OtherInsurance.where(distributor_id: @distributor.id).count rescue 0 if defined?(OtherInsurance)

      if policy_count > 0
        error_messages << "#{policy_count} insurance policy(ies)"
      end

      if has_payouts
        payout_count = DistributorPayout.where(distributor_id: @distributor.id).count rescue 0
        error_messages << "#{payout_count} payout record(s)" if payout_count > 0
      end

      message = "Cannot delete ambassador with #{error_messages.join(', ')}. Please reassign or remove these records first."
      redirect_to admin_distributors_path, alert: message
    else
      begin
        # Delete associated records that don't have proper cascade setup
        @distributor.distributor_documents.destroy_all
        @distributor.distributor_assignments.destroy_all

        # Now destroy the distributor
        @distributor.destroy!
        redirect_to admin_distributors_path, notice: 'Ambassador was successfully deleted.'
      rescue => e
        redirect_to admin_distributors_path,
                    alert: "Failed to delete ambassador: #{e.message}"
      end
    end
  end

  # PATCH /admin/distributors/1/toggle_status
  def toggle_status
    @distributor = Distributor.find(params[:id])
    new_status = @distributor.active? ? :inactive : :active

    if @distributor.update(status: new_status)
      redirect_to admin_distributors_path, notice: "Distributor status updated to #{new_status}."
    else
      redirect_to admin_distributors_path, alert: 'Failed to update status.'
    end
  end

  private

  def set_distributor
    @distributor = Distributor.find(params[:id])
  end

  def distributor_params
    params.require(:distributor).permit(
      :first_name, :middle_name, :last_name, :mobile, :email, :role_id,
      :state_id, :city_id, :birth_date, :gender, :pan_no, :gst_no,
      :company_name, :address, :bank_name, :account_no, :ifsc_code,
      :account_holder_name, :account_type, :upi_id, :status, :upload_main_document,
      distributor_documents_attributes: [:id, :document_type, :document_file, :_destroy],
      uploaded_documents_attributes: [:id, :title, :description, :document_type, :file, :uploaded_by, :_destroy]
    )
  end

  def handle_affiliate_assignments(distributor, assigned_affiliate_ids)
    return unless assigned_affiliate_ids.is_a?(Array)

    # Remove existing assignments
    distributor.distributor_assignments.destroy_all

    # Create new assignments
    assigned_affiliate_ids.reject(&:blank?).each do |sub_agent_id|
      sub_agent = SubAgent.find_by(id: sub_agent_id)
      if sub_agent
        # Remove any existing assignment for this sub_agent
        DistributorAssignment.where(sub_agent: sub_agent).destroy_all

        # Create new assignment
        distributor.distributor_assignments.create!(
          sub_agent: sub_agent,
          assigned_at: Time.current
        )
      end
    end
  end

  def build_affiliate_stats(affiliates)
    affiliate_ids = affiliates.map(&:id)
    return {} if affiliate_ids.empty?

    health_counts = HealthInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).count
    health_premiums = HealthInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).sum(:total_premium)
    health_commissions = HealthInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).sum(:commission_amount)
    health_customer_ids = Hash.new { |h, k| h[k] = [] }
    HealthInsurance.where(sub_agent_id: affiliate_ids).pluck(:sub_agent_id, :customer_id).each do |sid, cid|
      health_customer_ids[sid] << cid if cid
    end

    life_counts = LifeInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).count
    life_premiums = LifeInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).sum(:total_premium)
    life_commissions = LifeInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).sum(:commission_amount)
    life_customer_ids = Hash.new { |h, k| h[k] = [] }
    LifeInsurance.where(sub_agent_id: affiliate_ids).pluck(:sub_agent_id, :customer_id).each do |sid, cid|
      life_customer_ids[sid] << cid if cid
    end

    motor_counts = MotorInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).count
    motor_premiums = MotorInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).sum(:total_premium)
    motor_commissions = MotorInsurance.where(sub_agent_id: affiliate_ids).group(:sub_agent_id).sum(:main_agent_commission_amount)
    motor_customer_ids = Hash.new { |h, k| h[k] = [] }
    MotorInsurance.where(sub_agent_id: affiliate_ids).pluck(:sub_agent_id, :customer_id).each do |sid, cid|
      motor_customer_ids[sid] << cid if cid
    end

    recent_by_affiliate = build_recent_policies_for_affiliates(affiliate_ids)

    affiliates.each_with_object({}) do |affiliate, stats|
      id = affiliate.id

      # Safely try to get other policies if the association exists
      other_policies_count = 0
      other_policies_premium = 0.0
      other_policies_commission = 0.0

      begin
        # Try to get other insurance through customers
        affiliate_customers = Customer.where(sub_agent_id: id)
        if defined?(OtherInsurance) && OtherInsurance.respond_to?(:joins)
          other_policies = OtherInsurance.joins(:policy).where(policies: { customer_id: affiliate_customers.pluck(:id) })
          other_policies_count = other_policies.count
          other_policies_premium = other_policies.sum(:total_premium).to_f rescue 0.0
          other_policies_commission = other_policies.sum(:commission_amount).to_f rescue 0.0
        end
      rescue => e
        Rails.logger.debug "Could not load other insurance data: #{e.message}"
        other_policies_count = 0
        other_policies_premium = 0.0
        other_policies_commission = 0.0
      end

      total_policies = health_counts[id].to_i + life_counts[id].to_i + motor_counts[id].to_i + other_policies_count
      total_premium = health_premiums[id].to_f + life_premiums[id].to_f + motor_premiums[id].to_f + other_policies_premium
      total_commission = health_commissions[id].to_f + life_commissions[id].to_f + motor_commissions[id].to_f + other_policies_commission

      unique_customers_count = (health_customer_ids[id] + life_customer_ids[id] + motor_customer_ids[id]).uniq.count

      stats[id] = {
        total_policies: total_policies,
        total_premium: total_premium,
        total_commission: total_commission,
        health_policies: health_counts[id].to_i,
        life_policies: life_counts[id].to_i,
        motor_policies: motor_counts[id].to_i,
        other_policies: other_policies_count,
        recent_policies: recent_by_affiliate[id] || [],
        customers_count: unique_customers_count,
        joined_date: affiliate.created_at
      }
    end
  end

  def calculate_distributor_stats
    total_policies = 0
    total_premium = 0.0
    total_commission = 0.0
    total_customers = 0

    @assigned_affiliates.each do |affiliate|
      stats = @affiliate_stats[affiliate.id]
      total_policies += stats[:total_policies]
      total_premium += stats[:total_premium]
      total_commission += stats[:total_commission]
      total_customers += stats[:customers_count]
    end

    {
      total_affiliates: @assigned_affiliates.count,
      active_affiliates: @assigned_affiliates.count(&:active?),
      total_policies: total_policies,
      total_premium: total_premium,
      total_commission: total_commission,
      total_customers: total_customers,
      avg_policies_per_affiliate: @assigned_affiliates.count > 0 ? (total_policies.to_f / @assigned_affiliates.count).round(2) : 0
    }
  end

  def build_recent_policies_for_affiliates(affiliate_ids)
    health_by_affiliate = HealthInsurance.where(sub_agent_id: affiliate_ids)
                                          .includes(:customer)
                                          .order(created_at: :desc)
                                          .group_by(&:sub_agent_id)

    life_by_affiliate = LifeInsurance.where(sub_agent_id: affiliate_ids)
                                      .includes(:customer)
                                      .order(created_at: :desc)
                                      .group_by(&:sub_agent_id)

    motor_by_affiliate = MotorInsurance.where(sub_agent_id: affiliate_ids)
                                        .includes(:customer)
                                        .order(created_at: :desc)
                                        .group_by(&:sub_agent_id)

    affiliate_ids.each_with_object({}) do |id, result|
      policies = []

      (health_by_affiliate[id] || []).first(3).each do |policy|
        policies << {
          type: 'Health',
          policy_number: policy.policy_number,
          customer: policy.customer&.display_name || 'Unknown',
          premium: policy.total_premium,
          created_at: policy.created_at
        }
      end

      (life_by_affiliate[id] || []).first(3).each do |policy|
        policies << {
          type: 'Life',
          policy_number: policy.policy_number,
          customer: policy.customer&.display_name || 'Unknown',
          premium: policy.total_premium,
          created_at: policy.created_at
        }
      end

      (motor_by_affiliate[id] || []).first(2).each do |policy|
        policies << {
          type: 'Motor',
          policy_number: policy.policy_number,
          customer: policy.customer&.display_name || 'Unknown',
          premium: policy.total_premium,
          created_at: policy.created_at
        }
      end

      # Sort by creation date and return top 5
      result[id] = policies.sort_by { |p| p[:created_at] }.reverse.first(5)
    end
  end
end
