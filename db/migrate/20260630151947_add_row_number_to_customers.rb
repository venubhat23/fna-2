class AddRowNumberToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :row_number, :integer
  end
end
