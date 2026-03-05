class Referral < ApplicationRecord
  # Associations
  belongs_to :affiliate, optional: true
  belongs_to :referring_customer, class_name: 'Customer', optional: true
  belongs_to :customer, optional: true # Only set when referred person registers

  # Validations
  validates :referred_name, presence: true, length: { maximum: 255 }
  validates :referred_mobile, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :referred_email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :referral_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending registered converted] }
  validate :has_referrer

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :registered, -> { where(status: 'registered') }
  scope :converted, -> { where(status: 'converted') }
  scope :by_affiliate, ->(affiliate_id) { where(affiliate_id: affiliate_id) }
  scope :by_customer, ->(customer_id) { where(referring_customer_id: customer_id) }
  scope :customer_referrals, -> { where.not(referring_customer_id: nil) }
  scope :affiliate_referrals, -> { where.not(affiliate_id: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_defaults, on: :create

  # Instance methods
  def status_badge_class
    case status
    when 'pending' then 'warning'
    when 'registered' then 'info'
    when 'converted' then 'success'
    else 'secondary'
    end
  end

  def status_display
    status.humanize
  end

  def days_since_referral
    return 0 unless referral_date
    (Date.current - referral_date).to_i
  end

  def mark_as_registered!(customer)
    update!(
      status: 'registered',
      customer: customer,
      notes: "Customer registered on #{Date.current}"
    )
  end

  def mark_as_converted!
    update!(
      status: 'converted',
      converted_at: Time.current,
      notes: (notes.to_s + " | Converted on #{Date.current}").strip
    )
  end

  # Class methods
  def self.conversion_rate(affiliate_id = nil)
    scope = affiliate_id ? by_affiliate(affiliate_id) : all
    total = scope.count
    converted = scope.converted.count

    return 0 if total.zero?
    ((converted.to_f / total) * 100).round(2)
  end

  def referrer_name
    if referring_customer.present?
      referring_customer.display_name
    elsif affiliate.present?
      affiliate.display_name
    else
      "Unknown Referrer"
    end
  end

  def referrer_type
    if referring_customer.present?
      "Customer"
    elsif affiliate.present?
      "Affiliate"
    else
      "Unknown"
    end
  end

  private

  def set_defaults
    self.referral_date ||= Date.current
    self.status ||= 'pending'
  end

  def has_referrer
    if affiliate_id.blank? && referring_customer_id.blank?
      errors.add(:base, "Either affiliate or referring customer must be present")
    end

    if affiliate_id.present? && referring_customer_id.present?
      errors.add(:base, "Cannot have both affiliate and customer as referrer")
    end
  end
end
