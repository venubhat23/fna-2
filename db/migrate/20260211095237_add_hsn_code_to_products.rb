class AddHsnCodeToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :hsn_code, :string
  end
end
