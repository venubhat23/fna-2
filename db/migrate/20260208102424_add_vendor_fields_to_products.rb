class AddVendorFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :unit_type, :string
    add_column :products, :minimum_stock_alert, :integer
    add_column :products, :default_selling_price, :decimal
  end
end
