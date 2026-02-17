class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name
      t.text :description
      t.boolean :status
      t.text :permissions

      t.timestamps
    end
  end
end
