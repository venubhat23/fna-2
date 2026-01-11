class AddBuyingPriceToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :buying_price, :decimal, precision: 10, scale: 2
  end
end
