class CustomerFormat < ApplicationRecord
  belongs_to :customer
  belongs_to :product
  belongs_to :delivery_person

  PATTERN_OPTIONS = [
    'every_day',
    'alternative_day',
    'weekly_once',
    'weekly_twice',
    'weekly_thrice',
    'weekly_four',
    'weekly_five',
    'weekly_six',
    'random'
  ].freeze

  STATUS_OPTIONS = ['active', 'not_active'].freeze

  validates :pattern, inclusion: { in: PATTERN_OPTIONS }
  validates :status, inclusion: { in: STATUS_OPTIONS }
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'not_active') }
end
