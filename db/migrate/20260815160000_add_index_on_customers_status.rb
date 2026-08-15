class AddIndexOnCustomersStatus < ActiveRecord::Migration[8.0]
  def change
    # Customer.active / Customer.where(status: ...) is used across 15+ call sites
    # (dashboard, insurance form dropdowns, invoices, mobile agent lookups, etc.) and
    # the column has no index, so every one of those queries full-scans the table.
    add_index :customers, :status
  end
end
