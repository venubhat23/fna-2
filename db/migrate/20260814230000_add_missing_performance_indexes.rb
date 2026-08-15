class AddMissingPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :orders, :customer_id
    add_index :orders, :user_id
    add_index :order_items, :order_id
    add_index :order_items, :product_id
    add_index :leads, :affiliate_id
    add_index :invoices, :payout_id
    add_index :invoices, [:payout_type, :payout_id]
    add_index :client_requests, :resolved_by_id
    add_index :users, :role_id
  end
end
