class AddDisplayOrderToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :display_order, :integer
  end
end
