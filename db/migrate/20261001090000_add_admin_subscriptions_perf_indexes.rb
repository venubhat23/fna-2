# Indexes for the admin subscriptions list (Admin::SubscriptionsController#index).
# Built CONCURRENTLY so they don't lock milk_delivery_tasks writes in production.
class AddAdminSubscriptionsPerfIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Month filter + "today" stats: delivery_date range -> subscription_id, index-only.
    add_index :milk_delivery_tasks, [:delivery_date, :subscription_id],
              name: 'idx_mdt_delivery_date_subscription',
              algorithm: :concurrently, if_not_exists: true

    # Per-row GROUP BY (subscription_id, status) with SUM(quantity), index-only.
    add_index :milk_delivery_tasks, [:subscription_id, :status],
              include: [:quantity],
              name: 'idx_mdt_subscription_status_incl_qty',
              algorithm: :concurrently, if_not_exists: true

    # Delivery person filter: delivery_person_id -> subscription_id, index-only.
    add_index :milk_delivery_tasks, [:delivery_person_id, :subscription_id],
              name: 'idx_mdt_delivery_person_subscription',
              algorithm: :concurrently, if_not_exists: true
  end
end
