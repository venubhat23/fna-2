class CreateMilkDeliveryTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :milk_delivery_tasks do |t|
      t.references :subscription, null: false, foreign_key: { to_table: :milk_subscriptions }
      t.references :customer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2
      t.string :unit
      t.date :delivery_date
      t.references :delivery_person, null: true, foreign_key: true
      t.string :status, default: 'pending'
      t.datetime :assigned_at
      t.datetime :completed_at
      t.text :delivery_notes

      t.timestamps
    end

    add_index :milk_delivery_tasks, :delivery_date
    add_index :milk_delivery_tasks, [:customer_id, :delivery_date]
    add_index :milk_delivery_tasks, [:delivery_person_id, :delivery_date]
    add_index :milk_delivery_tasks, :status
  end
end
