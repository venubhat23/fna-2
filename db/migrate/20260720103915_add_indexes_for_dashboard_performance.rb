class AddIndexesForDashboardPerformance < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # /dashboard (DashboardController#index) joins/filters/groups on these columns
  # with no supporting index, forcing full table scans on every page load.
  def change
    add_index :booking_items, :booking_id, algorithm: :concurrently, if_not_exists: true
    add_index :booking_items, :product_id, algorithm: :concurrently, if_not_exists: true

    add_index :orders, :status, algorithm: :concurrently, if_not_exists: true

    add_index :customers, :created_at, algorithm: :concurrently, if_not_exists: true

    add_index :vendor_purchases, :status, algorithm: :concurrently, if_not_exists: true
  end
end
