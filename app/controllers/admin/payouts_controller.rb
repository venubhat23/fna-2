class Admin::PayoutsController < Admin::ApplicationController
  before_action :authenticate_user!
  before_action :set_payout, only: [:show, :edit, :update, :destroy, :mark_as_paid, :mark_as_processing, :cancel_payout, :audit_trail, :flow_timeline]

  def index
    @payouts = CommissionPayout.all

    # Search functionality
    if params[:search].present?
      search_term = params[:search].strip
      if search_term.length >= 3
        @payouts = @payouts.search_payouts(search_term)
      elsif search_term.length > 0
        @payouts = @payouts.none
      end
    end

    # Filter by policy type
    if params[:policy_type].present? && params[:policy_type] != 'all'
      @payouts = @payouts.where(policy_type: params[:policy_type])
    end

    # Filter by status
    if params[:status].present? && params[:status] != 'all'
      @payouts = @payouts.where(status: params[:status])
    end

    # Filter by payout recipient
    if params[:payout_to].present? && params[:payout_to] != 'all'
      @payouts = @payouts.where(payout_to: params[:payout_to])
    end

    # Date range filter
    if params[:date_from].present? && params[:date_to].present?
      @payouts = @payouts.where(payout_date: params[:date_from]..params[:date_to])
    end

    # Default ordering and pagination
    @payouts = @payouts.includes(:payout_audit_logs)
                       .order(payout_date: :desc, created_at: :desc)
                       .page(params[:page])
                       .per(20)

    # Summary statistics
    @summary = {
      total_payouts: CommissionPayout.count,
      total_amount: CommissionPayout.sum(:payout_amount),
      pending_amount: CommissionPayout.pending.sum(:payout_amount),
      paid_amount: CommissionPayout.paid.sum(:payout_amount),
      pending_count: CommissionPayout.pending.count,
      paid_count: CommissionPayout.paid.count,
      this_month: CommissionPayout.this_month.sum(:payout_amount),
      last_month: CommissionPayout.last_month.sum(:payout_amount)
    }

    # Chart data for dashboard
    @chart_data = prepare_chart_data

    respond_to do |format|
      format.html
      format.json { render json: { payouts: @payouts, summary: @summary } }
    end
  end

  def show
    @audit_logs = @payout.payout_audit_logs.recent.limit(10)
    @policy = @payout.policy
    @customer = @payout.customer
  end

  def new
    @payout = CommissionPayout.new
    @policies = available_policies_for_payout
  end

  def create
    @payout = CommissionPayout.new(payout_params)
    @payout.processed_by = current_user.email

    if @payout.save
      create_audit_log(@payout, 'created', "Payout created manually by #{current_user.email}")
      redirect_to admin_payout_path(@payout), notice: 'Payout was successfully created.'
    else
      @policies = available_policies_for_payout
      render :new
    end
  end

  def edit
  end

  def update
    if @payout.update(payout_params)
      create_audit_log(@payout, 'updated', "Payout updated by #{current_user.email}")
      redirect_to admin_payout_path(@payout), notice: 'Payout was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @payout.destroy
    create_audit_log(@payout, 'deleted', "Payout deleted by #{current_user.email}")
    redirect_to admin_payouts_path, notice: 'Payout was successfully deleted.'
  end

  def mark_as_paid
    payment_details = {
      payout_date: params[:payout_date] || Date.current,
      payment_mode: params[:payment_mode],
      transaction_id: params[:transaction_id],
      reference_number: params[:reference_number],
      notes: params[:notes],
      processed_by: current_user.email
    }

    if @payout.mark_as_paid!(payment_details)
      redirect_to admin_payout_path(@payout), notice: 'Payout marked as paid successfully.'
    else
      redirect_to admin_payout_path(@payout), alert: 'Failed to mark payout as paid.'
    end
  end

  def mark_as_processing
    if @payout.mark_as_processing!
      redirect_to admin_payout_path(@payout), notice: 'Payout marked as processing.'
    else
      redirect_to admin_payout_path(@payout), alert: 'Failed to mark payout as processing.'
    end
  end

  def cancel_payout
    reason = params[:cancellation_reason] || 'Cancelled by admin'

    if @payout.cancel_payout!(reason)
      redirect_to admin_payout_path(@payout), notice: 'Payout cancelled successfully.'
    else
      redirect_to admin_payout_path(@payout), alert: 'Failed to cancel payout.'
    end
  end

  def audit_trail
    @audit_logs = @payout.payout_audit_logs.recent.includes(:auditable)
    render json: @audit_logs.map { |log| format_audit_log(log) }
  end

  def flow_timeline
    @audit_logs = @payout.payout_audit_logs.recent.includes(:auditable)
    @policy = @payout.policy
    @customer = @payout.customer
    @timeline_events = build_timeline_events

    respond_to do |format|
      format.html
      format.json { render json: @timeline_events }
    end
  end

  def commission_receipts
    @q = CommissionReceipt.ransack(params[:q])
    @q.sorts = 'received_date desc' if @q.sorts.empty?

    @receipts = @q.result(distinct: true)
                  .includes(:payout_distributions)
                  .page(params[:page])
                  .per(20)

    @receipt_summary = {
      total_received: CommissionReceipt.sum(:total_commission_received),
      total_distributed: PayoutDistribution.sum(:calculated_amount),
      pending_distribution: CommissionReceipt.pending_distribution.count,
      auto_distributed: CommissionReceipt.distributed.count
    }
  end

  def auto_distribute
    receipt_id = params[:receipt_id]
    @receipt = CommissionReceipt.find(receipt_id)

    if @receipt.auto_distribute_commission!
      redirect_to admin_payouts_commission_receipts_path,
                  notice: 'Commission distributed automatically.'
    else
      redirect_to admin_payouts_commission_receipts_path,
                  alert: 'Failed to distribute commission automatically.'
    end
  end

  def reports
    @date_range = params[:date_range] || 'this_month'
    @policy_type = params[:policy_type] || 'all'
    @recipient_type = params[:recipient_type] || 'all'

    @report_data = generate_payout_report(@date_range, @policy_type, @recipient_type)

    respond_to do |format|
      format.html
      format.json { render json: @report_data }
      format.csv { send_csv_report(@report_data) }
    end
  end

  def summary
    @summary_data = {
      overview: payout_overview,
      by_recipient: payout_by_recipient,
      by_policy_type: payout_by_policy_type,
      monthly_trend: monthly_payout_trend,
      recent_activities: recent_payout_activities
    }

    respond_to do |format|
      format.html
      format.json { render json: @summary_data }
    end
  end

  def policies_by_type
    policy_type = params[:policy_type]
    policies = []

    case policy_type
    when 'health_insurance', 'health'
      policies = HealthInsurance.includes(:customer)
                                .select(:id, :policy_number, :customer_id, :total_premium)
                                .limit(100)
                                .map do |policy|
        customer_name = policy.customer&.display_name || 'Unknown Customer'
        {
          id: policy.id,
          policy_number: policy.policy_number || "Policy ##{policy.id}",
          customer_name: customer_name,
          premium: policy.total_premium || 0
        }
      end
    when 'life_insurance', 'life'
      policies = LifeInsurance.includes(:customer)
                              .select(:id, :policy_number, :customer_id, :total_premium)
                              .limit(100)
                              .map do |policy|
        customer_name = policy.customer&.display_name || 'Unknown Customer'
        {
          id: policy.id,
          policy_number: policy.policy_number || "Policy ##{policy.id}",
          customer_name: customer_name,
          premium: policy.total_premium || 0
        }
      end
    when 'motor_insurance', 'motor'
      if defined?(MotorInsurance)
        policies = MotorInsurance.includes(:customer)
                                 .select(:id, :policy_number, :customer_id, :total_premium)
                                 .limit(100)
                                 .map do |policy|
          customer_name = policy.customer&.display_name || 'Unknown Customer'
          {
            id: policy.id,
            policy_number: policy.policy_number || "Policy ##{policy.id}",
            customer_name: customer_name,
            premium: policy.total_premium || 0
          }
        end
      end
    when 'general_insurance', 'general'
      if defined?(GeneralInsurance)
        policies = GeneralInsurance.includes(:customer)
                                   .select(:id, :policy_number, :customer_id, :total_premium)
                                   .limit(100)
                                   .map do |policy|
          customer_name = policy.customer&.display_name || 'Unknown Customer'
          {
            id: policy.id,
            policy_number: policy.policy_number || "Policy ##{policy.id}",
            customer_name: customer_name,
            premium: policy.total_premium || 0
          }
        end
      end
    end

    render json: policies
  rescue => e
    Rails.logger.error "Error fetching policies by type: #{e.message}"
    render json: { error: 'Failed to fetch policies' }, status: :internal_server_error
  end

  def policy_actions
    policy_id = params[:policy_id]
    policy_type = params[:policy_type] || 'health'

    # Find the policy based on type and ID
    policy = find_policy_by_type_and_id(policy_type, policy_id)

    unless policy
      render json: { error: 'Policy not found' }, status: :not_found
      return
    end

    # Check existing payouts for this policy
    existing_payouts = CommissionPayout.where(
      policy_type: policy_type,
      policy_id: policy_id
    )

    # Calculate commission breakdown
    commission_breakdown = CommissionCalculatorService.calculate_commission_breakdown(policy)

    actions = {
      policy: {
        id: policy.id,
        number: policy.policy_number,
        customer: policy.customer.display_name,
        premium: policy.total_premium,
        type: policy_type
      },
      commission_breakdown: commission_breakdown,
      existing_payouts: existing_payouts.map do |payout|
        {
          id: payout.id,
          payout_to: payout.payout_to,
          amount: payout.payout_amount,
          status: payout.status,
          payout_date: payout.payout_date,
          transaction_id: payout.transaction_id
        }
      end,
      available_actions: generate_available_actions(existing_payouts, commission_breakdown)
    }

    render json: actions
  rescue => e
    Rails.logger.error "Error fetching policy actions: #{e.message}"
    render json: { error: 'Failed to fetch policy actions' }, status: :internal_server_error
  end

  private

  def set_payout
    @payout = CommissionPayout.find(params[:id])
  end

  def payout_params
    params.require(:payout).permit(
      :policy_type, :policy_id, :payout_to, :payout_amount, :payout_date,
      :payment_mode, :transaction_id, :reference_number, :notes, :status,
      :commission_amount_received, :distribution_percentage
    )
  end

  def available_policies_for_payout
    # Get policies that don't have complete payouts yet
    health_policies = HealthInsurance.includes(:customer).limit(100)
    life_policies = LifeInsurance.includes(:customer).limit(100)
    motor_policies = MotorInsurance.includes(:customer).limit(100) rescue []

    policies = []

    health_policies.each do |policy|
      policies << {
        id: policy.id,
        type: 'health',
        number: policy.policy_number,
        customer: policy.customer.display_name,
        value: "Health - #{policy.policy_number} - #{policy.customer.display_name}"
      }
    end

    life_policies.each do |policy|
      policies << {
        id: policy.id,
        type: 'life',
        number: policy.policy_number,
        customer: policy.customer.display_name,
        value: "Life - #{policy.policy_number} - #{policy.customer.display_name}"
      }
    end

    policies
  end

  def prepare_chart_data
    {
      monthly_payouts: monthly_payout_data,
      status_distribution: status_distribution_data,
      recipient_breakdown: recipient_breakdown_data
    }
  end

  def monthly_payout_data
    12.times.map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime('%b %Y'),
        amount: CommissionPayout.where(
          payout_date: month..month.end_of_month
        ).sum(:payout_amount)
      }
    end.reverse
  end

  def status_distribution_data
    CommissionPayout.group(:status).sum(:payout_amount)
  end

  def recipient_breakdown_data
    CommissionPayout.group(:payout_to).sum(:payout_amount)
  end

  def generate_payout_report(date_range, policy_type, recipient_type)
    payouts = CommissionPayout.all

    # Apply date filter
    case date_range
    when 'this_month'
      payouts = payouts.this_month
    when 'last_month'
      payouts = payouts.last_month
    when 'this_year'
      payouts = payouts.where(payout_date: Date.current.beginning_of_year..Date.current.end_of_year)
    when 'last_year'
      payouts = payouts.where(payout_date: 1.year.ago.beginning_of_year..1.year.ago.end_of_year)
    end

    # Apply policy type filter
    payouts = payouts.for_policy_type(policy_type) if policy_type != 'all'

    # Apply recipient type filter
    payouts = payouts.for_payout_to(recipient_type) if recipient_type != 'all'

    {
      summary: {
        total_payouts: payouts.count,
        total_amount: payouts.sum(:payout_amount),
        paid_amount: payouts.paid.sum(:payout_amount),
        pending_amount: payouts.pending.sum(:payout_amount)
      },
      details: payouts.includes(:payout_audit_logs).order(payout_date: :desc),
      breakdowns: {
        by_status: payouts.group(:status).sum(:payout_amount),
        by_recipient: payouts.group(:payout_to).sum(:payout_amount),
        by_policy_type: payouts.group(:policy_type).sum(:payout_amount)
      }
    }
  end

  def payout_overview
    {
      total_payouts: CommissionPayout.count,
      total_amount: CommissionPayout.sum(:payout_amount),
      pending_amount: CommissionPayout.pending.sum(:payout_amount),
      paid_amount: CommissionPayout.paid.sum(:payout_amount),
      processing_amount: CommissionPayout.processing.sum(:payout_amount)
    }
  end

  def payout_by_recipient
    CommissionPayout.group(:payout_to)
                   .group(:status)
                   .sum(:payout_amount)
  end

  def payout_by_policy_type
    CommissionPayout.group(:policy_type)
                   .group(:status)
                   .sum(:payout_amount)
  end

  def monthly_payout_trend
    6.times.map do |i|
      month = i.months.ago
      {
        month: month.strftime('%b %Y'),
        paid: CommissionPayout.paid.where(
          payout_date: month.beginning_of_month..month.end_of_month
        ).sum(:payout_amount),
        pending: CommissionPayout.pending.where(
          created_at: month.beginning_of_month..month.end_of_month
        ).sum(:payout_amount)
      }
    end.reverse
  end

  def recent_payout_activities
    PayoutAuditLog.recent
                  .includes(:auditable)
                  .limit(10)
                  .map { |log| format_audit_log(log) }
  end

  def format_audit_log(log)
    {
      id: log.id,
      action: log.action.humanize,
      performed_by: log.performed_by,
      performed_at: log.created_at.strftime('%Y-%m-%d %H:%M:%S'),
      notes: log.notes,
      changes: log.formatted_changes
    }
  end

  def create_audit_log(payout, action, notes)
    PayoutAuditLog.create_log(
      payout,
      action,
      current_user.email,
      payout.saved_changes,
      notes,
      request.remote_ip
    )
  end

  def send_csv_report(report_data)
    csv_data = generate_csv(report_data)
    send_data csv_data,
              filename: "payout_report_#{Date.current}.csv",
              type: 'text/csv'
  end

  def generate_csv(report_data)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Policy Type', 'Policy ID', 'Customer', 'Recipient', 'Amount', 'Status', 'Date', 'Reference']

      report_data[:details].each do |payout|
        csv << [
          payout.policy_type.capitalize,
          payout.policy_number,
          payout.customer_name,
          payout.payout_to.humanize,
          payout.payout_amount,
          payout.status.capitalize,
          payout.payout_date&.strftime('%Y-%m-%d'),
          payout.reference_number
        ]
      end
    end
  end

  def build_timeline_events
    events = []

    # Policy creation event
    if @policy
      events << {
        type: 'policy_created',
        title: 'Policy Created',
        description: "Policy #{@policy.policy_number} was created for #{@customer&.display_name}",
        date: @policy.created_at,
        icon: 'bi-plus-circle',
        color: 'success'
      }
    end

    # Payout creation event
    events << {
      type: 'payout_created',
      title: 'Payout Created',
      description: "Commission payout of ₹#{@payout.payout_amount} created for #{@payout.payout_to}",
      date: @payout.created_at,
      icon: 'bi-cash-stack',
      color: 'primary'
    }

    # Add audit log events
    @audit_logs.each do |log|
      events << {
        type: log.action,
        title: log.action.humanize,
        description: log.notes || "Payout #{log.action} by #{log.performed_by}",
        date: log.created_at,
        icon: timeline_icon_for_action(log.action),
        color: timeline_color_for_action(log.action)
      }
    end

    # Sort by date
    events.sort_by { |event| event[:date] }.reverse
  end

  def find_policy_by_type_and_id(policy_type, policy_id)
    case policy_type.downcase
    when 'health', 'health_insurance'
      HealthInsurance.includes(:customer).find_by(id: policy_id)
    when 'life', 'life_insurance'
      LifeInsurance.includes(:customer).find_by(id: policy_id)
    when 'motor', 'motor_insurance'
      MotorInsurance.includes(:customer).find_by(id: policy_id) if defined?(MotorInsurance)
    when 'other', 'general', 'general_insurance'
      OtherInsurance.includes(:customer).find_by(id: policy_id) if defined?(OtherInsurance)
    end
  rescue
    nil
  end

  def generate_available_actions(existing_payouts, commission_breakdown)
    return [] if commission_breakdown.empty?

    actions = []
    payout_types = ['affiliate', 'ambassador', 'investor', 'company_expense']

    payout_types.each do |payout_type|
      existing_payout = existing_payouts.find { |p| p.payout_to == payout_type }
      expected_amount = commission_breakdown.dig(:payouts, payout_type.to_sym) || 0

      next if expected_amount <= 0

      if existing_payout
        case existing_payout.status
        when 'pending'
          actions << {
            type: 'mark_as_paid',
            payout_type: payout_type,
            payout_id: existing_payout.id,
            amount: existing_payout.payout_amount,
            description: "Mark #{payout_type} payout as paid"
          }
        when 'paid'
          actions << {
            type: 'view_details',
            payout_type: payout_type,
            payout_id: existing_payout.id,
            amount: existing_payout.payout_amount,
            description: "View #{payout_type} payout details"
          }
        end
      else
        actions << {
          type: 'create_payout',
          payout_type: payout_type,
          amount: expected_amount,
          description: "Create #{payout_type} payout"
        }
      end
    end

    actions
  end

  def timeline_icon_for_action(action)
    case action
    when 'created' then 'bi-plus-circle'
    when 'updated' then 'bi-pencil-square'
    when 'marked_paid' then 'bi-check-circle'
    when 'processing' then 'bi-clock'
    when 'cancelled' then 'bi-x-circle'
    when 'deleted' then 'bi-trash'
    else 'bi-circle'
    end
  end

  def timeline_color_for_action(action)
    case action
    when 'created' then 'primary'
    when 'updated' then 'info'
    when 'marked_paid' then 'success'
    when 'processing' then 'warning'
    when 'cancelled' then 'danger'
    when 'deleted' then 'danger'
    else 'secondary'
    end
  end
end