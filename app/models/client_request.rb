class ClientRequest < ApplicationRecord
  include PgSearch::Model

  # Associations
  belongs_to :resolved_by, class_name: 'User', optional: true
  belongs_to :assignee, class_name: 'User', optional: true

  # Validations
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true
  validates :description, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending in_progress resolved closed] }
  validates :priority, presence: true, inclusion: { in: %w[low medium high urgent] }
  validates :stage, presence: true, inclusion: { in: %w[new assigned investigating awaiting_customer in_development testing resolved closed escalated on_hold] }
  validates :submitted_at, presence: true

  # Enums
  STATUSES = %w[pending in_progress resolved closed].freeze
  PRIORITIES = %w[low medium high urgent].freeze
  STAGES = %w[new assigned investigating awaiting_customer in_development testing resolved closed escalated on_hold].freeze
  DEPARTMENTS = %w[technical support sales billing operations management].freeze

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :closed, -> { where(status: 'closed') }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :by_department, ->(department) { where(department: department) }
  scope :assigned_to, ->(user_id) { where(assignee_id: user_id) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :overdue, -> { where('estimated_resolution_time < ?', Time.current) }
  scope :recent, -> { order(submitted_at: :desc) }

  # Search
  pg_search_scope :search_requests,
    against: [:name, :email, :phone_number, :description, :admin_response],
    using: {
      tsearch: {
        prefix: true,
        any_word: true
      }
    }

  # Callbacks
  before_validation :set_submitted_at, on: :create
  before_validation :generate_ticket_number, on: :create
  before_validation :set_default_stage, on: :create
  before_update :set_resolved_at
  before_update :track_stage_changes
  after_update :update_stage_history, if: :saved_change_to_stage?

  # Instance methods
  def status_badge_class
    case status
    when 'pending'
      'badge-warning'
    when 'in_progress'
      'badge-info'
    when 'resolved'
      'badge-success'
    when 'closed'
      'badge-secondary'
    else
      'badge-light'
    end
  end

  def priority_badge_class
    case priority
    when 'low'
      'badge-light'
    when 'medium'
      'badge-primary'
    when 'high'
      'badge-warning'
    when 'urgent'
      'badge-danger'
    else
      'badge-light'
    end
  end

  def days_since_submission
    (Date.current - submitted_at.to_date).to_i
  end

  def resolved?
    %w[resolved closed].include?(status)
  end

  def stage_badge_class
    case stage
    when 'new' then 'badge-secondary'
    when 'assigned' then 'badge-info'
    when 'investigating' then 'badge-warning'
    when 'awaiting_customer' then 'badge-primary'
    when 'in_development' then 'badge-dark'
    when 'testing' then 'badge-warning'
    when 'resolved' then 'badge-success'
    when 'closed' then 'badge-secondary'
    when 'escalated' then 'badge-danger'
    when 'on_hold' then 'badge-secondary'
    else 'badge-light'
    end
  end

  def can_transition_to?(target_stage)
    case stage
    when 'new' then %w[assigned escalated on_hold closed].include?(target_stage)
    when 'assigned' then %w[investigating awaiting_customer in_development escalated on_hold closed].include?(target_stage)
    when 'investigating' then %w[awaiting_customer in_development testing resolved escalated on_hold].include?(target_stage)
    when 'awaiting_customer' then %w[investigating in_development escalated on_hold closed].include?(target_stage)
    when 'in_development' then %w[testing awaiting_customer resolved escalated].include?(target_stage)
    when 'testing' then %w[resolved in_development awaiting_customer escalated].include?(target_stage)
    when 'escalated' then %w[assigned investigating in_development resolved closed].include?(target_stage)
    when 'on_hold' then %w[new assigned investigating in_development].include?(target_stage)
    when 'resolved' then %w[closed reopened].include?(target_stage)
    when 'closed' then %w[reopened].include?(target_stage)
    else false
    end
  end

  def transition_to_stage!(new_stage, user: nil, notes: nil)
    return false unless can_transition_to?(new_stage)

    self.stage = new_stage
    self.stage_updated_at = Time.current
    self.assignee = user if user.present?

    # Update status based on stage
    self.status = case new_stage
    when 'new', 'assigned' then 'pending'
    when 'investigating', 'awaiting_customer', 'in_development', 'testing', 'escalated', 'on_hold' then 'in_progress'
    when 'resolved' then 'resolved'
    when 'closed' then 'closed'
    else status
    end

    save!
  end

  def estimated_hours_remaining
    return 0 unless estimated_resolution_time.present?
    [(estimated_resolution_time - Time.current) / 1.hour, 0].max.round
  end

  def is_overdue?
    estimated_resolution_time.present? && estimated_resolution_time < Time.current
  end

  def stage_duration
    return 0 unless stage_updated_at.present?
    (Time.current - stage_updated_at) / 1.hour
  end

  private

  def set_submitted_at
    self.submitted_at ||= Time.current
  end

  def generate_ticket_number
    return if ticket_number.present?

    # Generate ticket number in format: TKT-YYYYMMDD-XXXX
    date_part = Date.current.strftime('%Y%m%d')

    # Find the last ticket number for today
    last_ticket = ClientRequest.where("ticket_number LIKE ?", "TKT-#{date_part}-%")
                              .order(:ticket_number)
                              .last

    if last_ticket && last_ticket.ticket_number.match(/TKT-#{date_part}-(\d{4})/)
      sequence = $1.to_i + 1
    else
      sequence = 1
    end

    self.ticket_number = "TKT-#{date_part}-#{sequence.to_s.rjust(4, '0')}"
  end

  def set_resolved_at
    if status_changed? && resolved?
      self.resolved_at = Time.current
      self.actual_resolution_time = Time.current
    elsif status_changed? && !resolved?
      self.resolved_at = nil
      self.actual_resolution_time = nil
    end
  end

  def set_default_stage
    self.stage ||= 'new'
    self.stage_updated_at ||= Time.current
  end

  def track_stage_changes
    if will_save_change_to_stage?
      self.stage_updated_at = Time.current
    end
  end

  def update_stage_history
    return unless saved_change_to_stage?

    old_stage, new_stage = saved_change_to_stage
    history_entry = {
      from_stage: old_stage,
      to_stage: new_stage,
      changed_at: stage_updated_at,
      changed_by: nil # Set to nil for now, can be populated via controller
    }

    current_history = stage_history.present? ? JSON.parse(stage_history) : []
    current_history << history_entry

    update_column(:stage_history, current_history.to_json)
  end
end
