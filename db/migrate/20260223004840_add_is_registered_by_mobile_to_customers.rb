class AddIsRegisteredByMobileToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :is_registered_by_mobile, :boolean
  end
end
