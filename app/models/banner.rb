class Banner < ApplicationRecord
  # Image attachment
  has_one_attached :banner_image

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 500 }
  validates :display_start_date, :display_end_date, :display_location, presence: true
  validates :display_location, inclusion: { in: ['dashboard', 'login', 'home', 'sidebar'] }
  validates :status, inclusion: { in: [true, false] }
  validates :display_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :redirect_link, format: { with: URI::regexp }, allow_blank: true

  # Custom validation for date range
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where(status: false) }
  scope :current, -> { where('display_start_date <= ? AND display_end_date >= ?', Date.current, Date.current) }
  scope :by_location, ->(location) { where(display_location: location) }
  scope :ordered, -> { order(:display_order, :created_at) }

  # Enums
  enum :display_location, { dashboard: 'dashboard', login: 'login', home: 'home', sidebar: 'sidebar' }

  # Instance methods
  def active?
    status && current?
  end

  def current?
    Date.current.between?(display_start_date, display_end_date)
  end

  def expired?
    display_end_date < Date.current
  end

  def upcoming?
    display_start_date > Date.current
  end

  def display_location_humanized
    display_location.humanize
  end

  private

  def end_date_after_start_date
    return unless display_start_date && display_end_date

    if display_end_date < display_start_date
      errors.add(:display_end_date, 'must be after start date')
    end
  end
end
