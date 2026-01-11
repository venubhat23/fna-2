class AddRecurringScheduleToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :occasional_schedule_type, :string
    add_column :products, :occasional_recurring_from_day, :string
    add_column :products, :occasional_recurring_from_time, :time
    add_column :products, :occasional_recurring_to_day, :string
    add_column :products, :occasional_recurring_to_time, :time
  end
end
