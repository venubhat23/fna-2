class AddSubscriptionFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :subscription_id, :integer
    add_column :bookings, :is_subscription, :boolean
  end
end
