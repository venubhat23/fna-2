class AddAddressToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :address, :text
  end
end
