class Affiliate < ApplicationRecord
  has_one :user, as: :authenticatable, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :mobile, presence: true, uniqueness: true
  validates :commission_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }

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

  private

  def create_user_account
    password = generate_secure_password

    user = User.create!(
      first_name: first_name,
      last_name: last_name,
      email: email,
      mobile: mobile,
      password: password,
      password_confirmation: password,
      user_type: 'affiliate',
      role: 'affiliate',
      status: true,
      authenticatable: self
    )

    # Store the auto-generated password for display
    update_column(:auto_generated_password, password)
  end

  def generate_secure_password
    name_part = first_name[0..3].upcase.ljust(4, 'X')
    year_part = Date.current.year.to_s
    "#{name_part}@#{year_part}"
  end
end
