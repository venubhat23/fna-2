class CreateStockMovements < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:stock_movements)
      create_table :stock_movements do |t|
        t.references :product, null: false, foreign_key: true
        t.string :reference_type, null: false
        t.integer :reference_id
        t.string :movement_type, null: false
        t.decimal :quantity, precision: 10, scale: 2, null: false
        t.decimal :stock_before, precision: 10, scale: 2, null: false
        t.decimal :stock_after, precision: 10, scale: 2, null: false
        t.text :notes

        t.timestamps
      end
    end

    add_index :stock_movements, :product_id, name: 'idx_stock_movements_product_id' unless index_exists?(:stock_movements, :product_id, name: 'idx_stock_movements_product_id')
    add_index :stock_movements, [:reference_type, :reference_id], name: 'idx_stock_movements_ref_type_id' unless index_exists?(:stock_movements, [:reference_type, :reference_id], name: 'idx_stock_movements_ref_type_id')
    add_index :stock_movements, :movement_type, name: 'idx_stock_movements_movement_type' unless index_exists?(:stock_movements, :movement_type, name: 'idx_stock_movements_movement_type')
    add_index :stock_movements, :created_at, name: 'idx_stock_movements_created_at' unless index_exists?(:stock_movements, :created_at, name: 'idx_stock_movements_created_at')
    add_index :stock_movements, [:product_id, :created_at], name: 'idx_stock_movements_product_created' unless index_exists?(:stock_movements, [:product_id, :created_at], name: 'idx_stock_movements_product_created')
  end
end
