class AddMissingColumnsToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :customer_id, :integer
    add_column :invoices, :payment_status, :integer
  end
end
