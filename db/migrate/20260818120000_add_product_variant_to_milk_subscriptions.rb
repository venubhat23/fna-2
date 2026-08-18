class AddProductVariantToMilkSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_reference :milk_subscriptions, :product_variant, null: true, foreign_key: true
  end
end
