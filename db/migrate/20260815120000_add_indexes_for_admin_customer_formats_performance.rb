class AddIndexesForAdminCustomerFormatsPerformance < ActiveRecord::Migration[8.0]
  def change
    # admin/customer_formats#index filters by status and pattern, and groups by both
    # for the summary stat cards, on every request - neither column was indexed.
    add_index :customer_formats, :status
    add_index :customer_formats, :pattern
  end
end
