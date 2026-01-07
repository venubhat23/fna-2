class CommissionPayout < ApplicationRecord
  include PgSearch::Model

  # Set correct table name
  self.table_name = "commission_payouts"

  # Model name for Rails forms (to work with admin_payouts routes)
  def self.model_name
    @_model_name ||= ActiveModel::Name.new(self, nil, "Payout")
  end

  # Associations
  belongs_to :payout, optional: true
  has_many :payout_audit_logs, as: :auditable, dependent: :destroy

  # Enums
  enum :status, {
    pending: 'pending',
    processing: 'processing',
    paid: 'paid',
    cancelled: 'cancelled'
  }

  # Validations
  validates :policy_type, presence: true, inclusion: { in: ['health', 'life', 'motor', 'other'] }
  validates :policy_id, presence: true, numericality: { greater_than: 0 }
  validates :payout_to, presence: true, inclusion: { in: ['agent', 'main_agent', 'distributor', 'sub_agent', 'investor', 'affiliate', 'ambassador', 'company_expense'] }
  validates :payout_amount, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :for_policy_type, ->(type) { where(policy_type: type) }
  scope :for_payout_to, ->(recipient) { where(payout_to: recipient) }
  scope :recent, -> { order(payout_date: :desc, created_at: :desc) }
  scope :this_month, -> { where(payout_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :last_month, -> { where(payout_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }

  # Search configuration
  pg_search_scope :search_payouts,
    against: [:transaction_id, :reference_number, :notes],
    using: {
      tsearch: { prefix: true, any_word: true }
    }

  # Callbacks
  # after_create :create_audit_log
  # after_update :create_audit_log, if: :saved_changes?

  # Instance methods
  def policy
    case policy_type
    when 'health'
      HealthInsurance.find_by(id: policy_id)
    when 'life'
      LifeInsurance.find_by(id: policy_id)
    when 'motor'
      MotorInsurance.find_by(id: policy_id)
    when 'other'
      OtherInsurance.find_by(id: policy_id)
    end
  end

  def customer
    policy&.customer
  end

  def customer_name
    customer&.display_name || 'Unknown'
  end

  def policy_number
    policy&.policy_number || 'N/A'
  end

  def lead
    return nil unless lead_id.present?
    Lead.find_by(lead_id: lead_id)
  end

  def lead_details
    lead_record = lead
    return {} unless lead_record

    {
      lead_id: lead_record.lead_id,
      lead_name: lead_record.name,
      lead_stage: lead_record.current_stage,
      lead_source: lead_record.lead_source,
      product_interest: lead_record.product_interest
    }
  end

  def recipient
    case payout_to
    when 'sub_agent'
      SubAgent.find_by(id: policy&.sub_agent_id)
    when 'distributor'
      Distributor.find_by(id: policy&.distributor_id)
    when 'investor'
      Investor.find_by(id: policy&.investor_id)
    when 'agent'
      User.find_by(id: policy&.try(:agent_id)) # if there's an agent field
    end
  end

  def recipient_name
    recipient&.display_name || recipient&.full_name || 'Unknown'
  end

  def mark_as_paid!(payment_details = {})
    transaction do
      self.status = 'paid'
      self.payout_date = payment_details[:payout_date] || Date.current
      self.payment_mode = payment_details[:payment_mode]
      self.transaction_id = payment_details[:transaction_id]
      self.reference_number = payment_details[:reference_number]
      self.notes = payment_details[:notes]
      self.processed_by = payment_details[:processed_by] || 'system'
      self.processed_at = Time.current

      save!
      create_audit_log('marked_paid', 'Commission payout marked as paid')
    end
  end

  def mark_as_processing!
    update!(status: 'processing')
    create_audit_log('processing', 'Commission payout marked as processing')
  end

  def cancel_payout!(reason = nil)
    transaction do
      self.status = 'cancelled'
      self.notes = [notes, "Cancelled: #{reason}"].compact.join(' | ')
      save!
      create_audit_log('cancelled', reason)
    end
  end

  # Get related commission payouts for the same policy where main agent is paid
  def related_payouts_when_main_agent_paid
    return [] unless policy_type.present? && policy_id.present?

    # Find the main agent commission payout for this policy
    main_agent_payout = CommissionPayout.find_by(
      policy_type: policy_type,
      policy_id: policy_id,
      payout_to: 'main_agent',
      status: 'paid'
    )

    return [] unless main_agent_payout

    # If main agent is paid, return all other commission payouts for the same policy
    CommissionPayout.where(
      policy_type: policy_type,
      policy_id: policy_id
    ).where.not(payout_to: 'main_agent')
     .includes(:payout)
     .order(:created_at)
  end

  # Check if main agent payout is paid for this policy
  def main_agent_paid?
    CommissionPayout.exists?(
      policy_type: policy_type,
      policy_id: policy_id,
      payout_to: 'main_agent',
      status: 'paid'
    )
  end

  # Get main agent payout details for this policy
  def main_agent_payout
    CommissionPayout.find_by(
      policy_type: policy_type,
      policy_id: policy_id,
      payout_to: 'main_agent'
    )
  end

  # Class methods
  def self.total_pending_amount
    pending.sum(:payout_amount)
  end

  def self.total_paid_amount
    paid.sum(:payout_amount)
  end

  def self.summary_by_recipient
    group(:payout_to).group(:status).sum(:payout_amount)
  end

  def self.monthly_summary(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    where(payout_date: start_date..end_date).group(:payout_to).sum(:payout_amount)
  end

  # Get all dependent payouts where main agent is paid (class method)
  def self.where_main_agent_paid
    # Get all policy combinations where main agent is paid
    paid_main_agent_policies = where(payout_to: 'main_agent', status: 'paid')
                               .pluck(:policy_type, :policy_id)
                               .uniq

    return none if paid_main_agent_policies.empty?

    # Build conditions for all policies where main agent is paid
    conditions = paid_main_agent_policies.map do |policy_type, policy_id|
      "(policy_type = '#{policy_type}' AND policy_id = #{policy_id})"
    end.join(' OR ')

    # Return all payouts (including main agent) for these policies
    where(conditions).includes(:payout)
  end

  # Get only dependent payouts (excluding main agent) where main agent is paid
  def self.dependent_payouts_where_main_agent_paid
    where_main_agent_paid.where.not(payout_to: 'main_agent')
  end

  private

  def create_audit_log(action = nil, notes_text = nil)
    action ||= if saved_changes.key?('created_at')
                 'created'
               else
                 'updated'
               end

    payout_audit_logs.create!(
      action: action,
      changes: saved_changes.except('updated_at'),
      performed_by: 'system',
      notes: notes_text
    )
  end
end
