class Coupon < ApplicationRecord
  # Validations
  validates :code, presence: true, uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 20 },
            format: { with: /\A[A-Z0-9]+\z/, message: "must contain only uppercase letters and numbers" }
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed] }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :minimum_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :maximum_discount, numericality: { greater_than: 0 }, allow_nil: true
  validates :usage_limit, numericality: { greater_than: 0 }, allow_nil: true
  validates :used_count, numericality: { greater_than_or_equal_to: 0 }
  validates :valid_from, presence: true
  validates :valid_until, presence: true
  validate :valid_until_after_valid_from
  validate :discount_value_within_range

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }
  scope :valid, -> { active.where('valid_from <= ? AND valid_until >= ?', Time.current, Time.current) }
  scope :expired, -> { where('valid_until < ?', Time.current) }
  scope :upcoming, -> { where('valid_from > ?', Time.current) }
  scope :available, -> { valid.where('usage_limit IS NULL OR used_count < usage_limit') }
  scope :search, ->(query) { where('code ILIKE ? OR description ILIKE ?', "%#{query}%", "%#{query}%") }

  # Callbacks
  before_validation :normalize_code
  before_validation :set_defaults

  def active?
    status && valid_from <= Time.current && valid_until >= Time.current
  end

  def expired?
    valid_until < Time.current
  end

  def upcoming?
    valid_from > Time.current
  end

  def available?
    active? && (usage_limit.nil? || used_count < usage_limit)
  end

  def usage_remaining
    return 'Unlimited' if usage_limit.nil?
    usage_limit - used_count
  end

  def discount_display
    if discount_type == 'percentage'
      "#{discount_value.to_i}%"
    else
      "₹#{discount_value.to_i}"
    end
  end

  def validity_period
    "#{valid_from.strftime('%d %b %Y')} - #{valid_until.strftime('%d %b %Y')}"
  end

  def status_badge_class
    return 'secondary' unless status
    return 'danger' if expired?
    return 'info' if upcoming?
    return 'success' if available?
    'warning'
  end

  def status_text
    return 'Inactive' unless status
    return 'Expired' if expired?
    return 'Upcoming' if upcoming?
    return 'Active' if available?
    'Exhausted'
  end

  def apply_discount(amount)
    return 0 if !available? || amount < (minimum_amount || 0)

    discount = if discount_type == 'percentage'
      amount * (discount_value / 100)
    else
      discount_value
    end

    if maximum_discount.present?
      [discount, maximum_discount].min
    else
      discount
    end
  end

  def increment_usage!
    increment!(:used_count)
  end

  private

  def normalize_code
    self.code = code&.upcase&.strip if code.present?
  end

  def set_defaults
    self.used_count ||= 0
    self.status = true if status.nil?
  end

  def valid_until_after_valid_from
    return unless valid_from.present? && valid_until.present?
    errors.add(:valid_until, 'must be after valid from date') if valid_until <= valid_from
  end

  def discount_value_within_range
    return unless discount_type.present? && discount_value.present?

    if discount_type == 'percentage' && discount_value > 100
      errors.add(:discount_value, 'cannot exceed 100 for percentage discount')
    end
  end
end
