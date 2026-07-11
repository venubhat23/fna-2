class AddIndexesForAdminBookingsPerformance < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # admin/bookings#index filters/sorts on these columns with no supporting index,
  # forcing a full table scan (+ full sort for the default created_at ordering)
  # on every page load. admin/bookings#new does the same for products/stock_batches.
  def change
    add_index :bookings, :user_id, algorithm: :concurrently, if_not_exists: true
    add_index :bookings, :customer_id, algorithm: :concurrently, if_not_exists: true
    add_index :bookings, :status, algorithm: :concurrently, if_not_exists: true
    add_index :bookings, :created_at, algorithm: :concurrently, if_not_exists: true
    add_index :bookings, :invoice_number, algorithm: :concurrently, if_not_exists: true
    add_index :bookings, :booking_number, algorithm: :concurrently, if_not_exists: true

    add_index :stock_batches, [:product_id, :status], algorithm: :concurrently, if_not_exists: true
  end
end
