class AddIndexesForAdminSubscriptionsPerformance < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # /admin/subscriptions (Admin::SubscriptionsController#index) sorts by
  # customers.row_number on every page load and filters by delivery_person_id,
  # with no supporting index, forcing a full sort / scan on every request.
  def change
    add_index :customers, :row_number, algorithm: :concurrently, if_not_exists: true
    add_index :milk_subscriptions, :delivery_person_id, algorithm: :concurrently, if_not_exists: true
  end
end
