class AddMonthYearToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :month, :integer
    add_column :invoices, :year, :integer

    # Add indexes for better query performance
    add_index :invoices, [:month, :year]
    add_index :invoices, :month
    add_index :invoices, :year
  end
end
