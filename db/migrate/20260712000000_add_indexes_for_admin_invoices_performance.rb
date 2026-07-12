class AddIndexesForAdminInvoicesPerformance < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # admin/invoices#index filters/sorts on these columns with no supporting index,
  # forcing a full table scan on every page load.
  def change
    add_index :invoices, :customer_id, algorithm: :concurrently, if_not_exists: true
    add_index :invoices, :created_at, algorithm: :concurrently, if_not_exists: true
    add_index :invoices, :payment_status, algorithm: :concurrently, if_not_exists: true
  end
end
