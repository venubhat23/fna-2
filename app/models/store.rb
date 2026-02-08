class Store < ApplicationRecord
  # Associations
  has_many :bookings

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :city, presence: true
  validates :state, presence: true
  validates :pincode, presence: true, format: { with: /\A\d{6}\z/, message: "should be 6 digits" }
  validates :contact_mobile, presence: true, format: { with: /\A[6-9]\d{9}\z/, message: "should be a valid Indian mobile number" }

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }

  # Methods
  def display_name
    "#{name} - #{city}"
  end

  def full_address
    [address, city, state, pincode].compact.join(', ')
  end
end
