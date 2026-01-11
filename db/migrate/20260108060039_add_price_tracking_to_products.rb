class AddPriceTrackingToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :yesterday_price, :decimal, precision: 10, scale: 2
    add_column :products, :today_price, :decimal, precision: 10, scale: 2
    add_column :products, :price_change_percentage, :decimal, precision: 5, scale: 2
    add_column :products, :last_price_update, :datetime
    add_column :products, :price_history, :text

    add_index :products, :last_price_update
  end
end
