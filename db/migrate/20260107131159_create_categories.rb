class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :parent_id
      t.string :image
      t.boolean :status, default: true
      t.integer :display_order, default: 0

      t.timestamps
    end

    add_index :categories, :parent_id
    add_index :categories, :status
    add_index :categories, :display_order
  end
end
