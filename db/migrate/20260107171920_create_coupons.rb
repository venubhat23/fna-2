class CreateCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :coupons do |t|
      t.string :code
      t.text :description
      t.string :discount_type
      t.decimal :discount_value
      t.decimal :minimum_amount
      t.decimal :maximum_discount
      t.integer :usage_limit
      t.integer :used_count
      t.datetime :valid_from
      t.datetime :valid_until
      t.boolean :status
      t.text :applicable_products
      t.text :applicable_categories

      t.timestamps
    end
    add_index :coupons, :code, unique: true
  end
end
