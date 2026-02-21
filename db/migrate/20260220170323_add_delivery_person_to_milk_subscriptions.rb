class AddDeliveryPersonToMilkSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_reference :milk_subscriptions, :delivery_person, null: true, foreign_key: true
  end
end
