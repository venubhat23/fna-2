class Affiliate < ApplicationRecord
  has_one :user, as: :authenticatable, dependent: :destroy
  has_many :referrals, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :mobile, presence: true, uniqueness: true
  validates :commission_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }

  before_create :set_username
  after_create :create_user_account

  def display_name
    "#{first_name} #{last_name}".strip
  end

  def formatted_commission
    "#{commission_percentage}%"
  end

  def status_badge_class
    status? ? 'success' : 'danger'
  end

  def status_text
    status? ? 'Active' : 'Inactive'
  end

  # Referral statistics - one GROUP BY query per request (memoized on the instance)
  # instead of 6 separate COUNT round trips (total/pending/registered/converted/
  # conversion_rate's own total+converted queries), used together on every dashboard,
  # referrals index, and admin affiliate show page.
  def referral_status_counts
    @referral_status_counts ||= referrals.group(:status).count
  end

  def referral_stats
    @referral_stats ||= begin
      status_counts = referral_status_counts
      total = status_counts.values.sum
      converted = status_counts['converted'].to_i
      {
        total: total,
        pending: status_counts['pending'].to_i,
        registered: status_counts['registered'].to_i,
        converted: converted,
        conversion_rate: total.zero? ? 0 : ((converted.to_f / total) * 100).round(2)
      }
    end
  end

  def total_referrals
    referral_stats[:total]
  end

  def pending_referrals
    referral_stats[:pending]
  end

  def registered_referrals
    referral_stats[:registered]
  end

  def converted_referrals
    referral_stats[:converted]
  end

  def conversion_rate
    referral_stats[:conversion_rate]
  end

  private

  def set_username
    self.username ||= generate_username
  end

  def create_user_account
    password = generate_secure_password
    affiliate_role = Role.find_by(name: 'affiliate')

    user = User.create!(
      first_name: first_name,
      last_name: last_name,
      email: email,
      mobile: mobile,
      password: password,
      password_confirmation: password,
      user_type: 'affiliate',
      role: affiliate_role,
      status: true
    )

    # Store the auto-generated password for display
    update_column(:auto_generated_password, password)
  end

  def generate_secure_password
    name_part = first_name[0..3].upcase.ljust(4, 'X')
    year_part = Date.current.year.to_s
    "#{name_part}@#{year_part}"
  end

  def generate_username
    base_username = "#{first_name.downcase}#{last_name.downcase}".gsub(/[^a-z0-9]/, '')
    counter = 1
    username = base_username

    while User.exists?(email: "#{username}@affiliate.com")
      username = "#{base_username}#{counter}"
      counter += 1
    end

    username
  end
end
