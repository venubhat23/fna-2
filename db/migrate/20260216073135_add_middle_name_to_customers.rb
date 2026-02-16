class AddMiddleNameToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :middle_name, :string
  end
end
