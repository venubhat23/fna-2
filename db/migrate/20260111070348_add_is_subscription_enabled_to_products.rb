class AddIsSubscriptionEnabledToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :is_subscription_enabled, :boolean, default: false
    add_index :products, :is_subscription_enabled
  end
end
