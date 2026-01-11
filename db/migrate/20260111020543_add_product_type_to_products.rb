class AddProductTypeToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :product_type, :string, default: 'Grocery'
    add_index :products, :product_type
  end
end
