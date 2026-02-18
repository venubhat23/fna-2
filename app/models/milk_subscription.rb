class MilkSubscription < ApplicationRecord
  belongs_to :customer
  belongs_to :product
  has_many :milk_delivery_tasks, foreign_key: 'subscription_id', dependent: :destroy

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  enum :status, { active: 'active', paused: 'paused', expired: 'expired', cancelled: 'cancelled' }
  enum :delivery_pattern, { daily: 'daily', alternate: 'alternate', specific_dates: 'specific_dates' }

  scope :active_subscriptions, -> { where(status: 'active', is_active: true) }
  scope :for_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }

  after_create :generate_all_delivery_tasks

  def total_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end

  def delivery_dates_array
    return [] unless start_date && end_date

    case delivery_pattern
    when 'daily'
      (start_date..end_date).to_a
    when 'alternate'
      dates = []
      current_date = start_date
      while current_date <= end_date
        dates << current_date
        current_date += 2.days
      end
      dates
    when 'specific_dates'
      return [] unless specific_dates.present?
      JSON.parse(specific_dates).map { |date| Date.parse(date) } rescue []
    else
      []
    end
  end

  def generate_all_delivery_tasks
    delivery_dates_array.each do |date|
      milk_delivery_tasks.create!(
        customer: customer,
        product: product,
        quantity: quantity,
        unit: unit,
        delivery_date: date,
        status: 'pending'
      )
    end
  end

  def completed_deliveries_count
    milk_delivery_tasks.where(status: 'completed').count
  end

  def pending_deliveries_count
    milk_delivery_tasks.where(status: 'pending').count
  end

  def total_deliveries_count
    milk_delivery_tasks.count
  end

  def completion_percentage
    return 0 if total_deliveries_count == 0
    (completed_deliveries_count.to_f / total_deliveries_count * 100).round(2)
  end

  def subscription_summary
    {
      total_days: total_days,
      total_deliveries: total_deliveries_count,
      completed: completed_deliveries_count,
      pending: pending_deliveries_count,
      completion_rate: completion_percentage
    }
  end

  def total_quantity
    (delivery_dates_array.count * quantity).round(2)
  end

  def calculate_total_amount
    price_per_unit = product&.price || 0
    (total_quantity * price_per_unit).round(2)
  end

  def self.generate_subscription_number
    last_subscription = MilkSubscription.order(:created_at).last
    if last_subscription && last_subscription.id
      "SUB-#{Date.current.strftime('%Y')}-#{sprintf('%04d', last_subscription.id + 1)}"
    else
      "SUB-#{Date.current.strftime('%Y')}-0001"
    end
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
end