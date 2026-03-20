class ImportProgress < ApplicationRecord
  validates :job_id, presence: true, uniqueness: true
  validates :total_items, presence: true, numericality: { greater_than: 0 }
  validates :processed_items, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[started processing completed failed] }

  def percentage_complete
    return 0 if total_items.zero?
    [(processed_items.to_f / total_items * 100).round(2), 100].min
  end

  def estimated_time_remaining
    return nil if processed_items.zero? || status == 'completed'

    elapsed_time = Time.current - created_at
    rate = processed_items.to_f / elapsed_time.to_f
    remaining_items = total_items - processed_items

    remaining_items / rate
  end

  def update_progress!(processed:, status: nil, message: nil)
    attributes = {
      processed_items: processed,
      updated_at: Time.current
    }
    attributes[:status] = status if status
    attributes[:message] = message if message

    update!(attributes)
  end
end