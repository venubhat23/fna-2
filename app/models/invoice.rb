class Invoice < ApplicationRecord
  # Associations - these are conditional associations
  # Note: We'll keep the polymorphic method approach since the associations depend on payout_type

  validates :invoice_number, presence: true, uniqueness: true
  validates :payout_type, presence: true, inclusion: { in: %w[affiliate distributor ambassador commission] }
  validates :payout_id, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending paid cancelled] }
  validates :invoice_date, presence: true
  validates :due_date, presence: true

  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :overdue, -> { where('due_date < ? AND status = ?', Date.current, 'pending') }

  # Polymorphic association to get the payout record
  def payout_record
    case payout_type
    when 'affiliate'
      CommissionPayout.find_by(id: payout_id, payout_to: 'affiliate')
    when 'distributor'
      DistributorPayout.find_by(id: payout_id)
    when 'ambassador'
      CommissionPayout.find_by(id: payout_id, payout_to: 'ambassador')
    when 'commission'
      Payout.find_by(id: payout_id)
    end
  end

  def payout_recipient
    case payout_type
    when 'affiliate'
      # For affiliate type, payout_id refers to SubAgent ID
      sub_agent = SubAgent.find_by(id: payout_id)
      if sub_agent
        "#{sub_agent.first_name} #{sub_agent.last_name}".strip
      else
        'Unknown Affiliate'
      end
    when 'distributor'
      payout = payout_record
      distributor = payout&.distributor
      distributor&.display_name || 'Unknown Distributor'
    when 'ambassador'
      payout = payout_record
      # For ambassador, get distributor info from policy
      if payout
        policy = get_policy_from_commission_payout(payout)
        distributor = Distributor.find_by(id: policy&.distributor_id) if policy&.respond_to?(:distributor_id)
        distributor&.display_name || 'Unknown Ambassador'
      else
        'Unknown Ambassador'
      end
    when 'commission'
      'Main Agent Commission'
    else
      'Unknown'
    end
  end

  def formatted_amount
    "₹#{total_amount.to_f.round(2).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  def overdue?
    due_date < Date.current && status == 'pending'
  end

  def days_overdue
    return 0 unless overdue?
    (Date.current - due_date).to_i
  end

  def mark_as_paid!
    update!(status: 'paid', paid_at: Time.current)
  end

  private

  def get_policy_from_commission_payout(commission_payout)
    case commission_payout.policy_type
    when 'health'
      HealthInsurance.find_by(id: commission_payout.policy_id)
    when 'life'
      LifeInsurance.find_by(id: commission_payout.policy_id)
    when 'motor'
      MotorInsurance.find_by(id: commission_payout.policy_id)
    when 'other'
      OtherInsurance.find_by(id: commission_payout.policy_id)
    end
  end
end
