class AddBasePriceToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :base_price_excluding_gst, :decimal
  end
end
