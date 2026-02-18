class MilkDeliveryTask < ApplicationRecord
  belongs_to :subscription, class_name: 'MilkSubscription'
  belongs_to :customer
  belongs_to :product
  belongs_to :delivery_person, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :delivery_date, presence: true

  enum :status, { pending: 'pending', assigned: 'assigned', delivered: 'delivered', cancelled: 'cancelled', missed: 'missed' }

  scope :for_today, -> { where(delivery_date: Date.current) }
  scope :for_tomorrow, -> { where(delivery_date: Date.tomorrow) }
  scope :for_date, ->(date) { where(delivery_date: date) }
  scope :for_delivery_person, ->(delivery_person_id) { where(delivery_person_id: delivery_person_id) }
  scope :unassigned, -> { where(delivery_person_id: nil, status: 'pending') }

  def mark_as_completed!
    update!(
      status: 'completed',
      completed_at: Time.current
    )
  end

  def mark_as_delivered!(delivery_person, notes = nil)
    update!(
      status: 'delivered',
      delivery_person: delivery_person,
      assigned_at: Time.current,
      completed_at: Time.current,
      delivery_notes: notes
    )
  end

  def assign_to_delivery_person!(delivery_person)
    update!(
      delivery_person: delivery_person,
      status: 'assigned',
      assigned_at: Time.current
    )
  end

  def customer_info
    "#{customer.first_name} #{customer.last_name}".strip
  end

  def delivery_address
    customer.address
  end

  def product_details
    "#{product.name} - #{quantity} #{unit}"
  end

  def self.create_daily_tasks_for_date(date)
    # Find all active subscriptions that should have delivery on this date
    MilkSubscription.active_subscriptions.each do |subscription|
      next unless subscription.delivery_dates_array.include?(date)
      next if subscription.milk_delivery_tasks.exists?(delivery_date: date)

      subscription.milk_delivery_tasks.create!(
        customer: subscription.customer,
        product: subscription.product,
        quantity: subscription.quantity,
        unit: subscription.unit,
        delivery_date: date,
        status: 'pending'
      )
    end
  end

  def self.assign_tasks_to_delivery_person(task_ids, delivery_person_id)
    tasks = where(id: task_ids, status: 'pending')
    tasks.update_all(
      delivery_person_id: delivery_person_id,
      status: 'assigned',
      assigned_at: Time.current
    )
  end

  def self.todays_summary
    today_tasks = for_today
    {
      total: today_tasks.count,
      pending: today_tasks.pending.count,
      assigned: today_tasks.assigned.count,
      delivered: today_tasks.delivered.count,
      cancelled: today_tasks.cancelled.count
    }
  end
end