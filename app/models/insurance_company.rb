class InsuranceCompany < ApplicationRecord
  has_many :brokers, dependent: :nullify

  validates :name, presence: true
end
