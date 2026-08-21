class CustomerAddress < ApplicationRecord
  belongs_to :customer

  validates :name, :mobile, :address, :city, presence: true
  validates :pincode, presence: true, format: { with: /\A\d{6}\z/, message: 'must be a 6-digit pincode' }
end
