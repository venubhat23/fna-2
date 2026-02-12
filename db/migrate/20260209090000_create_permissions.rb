class CreatePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :permissions do |t|
      t.string :name, null: false
      t.string :resource
      t.string :action
      t.text :description

      t.timestamps
    end

    add_index :permissions, :name, unique: true
    add_index :permissions, [:resource, :action]
  end
end