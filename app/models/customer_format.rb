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
  validates :days, presence: true, if: -> { pattern == 'random' }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'not_active') }

  # Serialize days as JSON for random pattern
  serialize :days, coder: JSON

  # Get selected days as array for random pattern
  def selected_days
    return [] unless pattern == 'random' && days.present?
    days.is_a?(Array) ? days : []
  end

  # Set selected days for random pattern
  def selected_days=(day_array)
    self.days = day_array.reject(&:blank?).map(&:to_i).sort if day_array.present?
  end
end
