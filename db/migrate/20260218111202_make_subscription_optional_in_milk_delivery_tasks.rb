class MakeSubscriptionOptionalInMilkDeliveryTasks < ActiveRecord::Migration[8.0]
  def change
    change_column_null :milk_delivery_tasks, :subscription_id, true
  end
end