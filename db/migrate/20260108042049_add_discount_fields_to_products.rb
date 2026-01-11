class AddDiscountFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :discount_type, :string # 'percentage' or 'fixed'
    add_column :products, :discount_value, :decimal, precision: 10, scale: 2
    add_column :products, :original_price, :decimal, precision: 10, scale: 2
    add_column :products, :discount_amount, :decimal, precision: 10, scale: 2
    add_column :products, :is_discounted, :boolean, default: false
  end
end
