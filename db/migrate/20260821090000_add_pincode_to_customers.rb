class AddPincodeToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :pincode, :string
    add_index :customers, :pincode
  end
end
