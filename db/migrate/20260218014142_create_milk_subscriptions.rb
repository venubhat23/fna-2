class CreateMilkSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :milk_subscriptions do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2
      t.string :unit, default: 'liter'
      t.date :start_date
      t.date :end_date
      t.string :delivery_time, default: 'morning'
      t.string :delivery_pattern, default: 'daily'
      t.text :specific_dates
      t.decimal :total_amount, precision: 10, scale: 2
      t.string :status, default: 'active'
      t.boolean :is_active, default: true
      t.integer :created_by

      t.timestamps
    end

    add_index :milk_subscriptions, :status, name: 'idx_milk_subscriptions_status'
    add_index :milk_subscriptions, [:start_date, :end_date], name: 'idx_milk_subscriptions_dates'
  end
end
