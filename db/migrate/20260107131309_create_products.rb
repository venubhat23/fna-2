class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :discount_price, precision: 10, scale: 2
      t.integer :stock, default: 0
      t.string :status, default: 'active'
      t.string :sku, null: false
      t.decimal :weight, precision: 8, scale: 3
      t.string :dimensions
      t.text :meta_title
      t.text :meta_description
      t.text :tags

      t.timestamps
    end

    add_index :products, :status
    add_index :products, :sku, unique: true
    add_index :products, :name
  end
end
