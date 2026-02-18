class CreateSubscriptionTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_templates do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :delivery_person, null: true, foreign_key: true
      t.decimal :quantity, precision: 8, scale: 2
      t.string :unit
      t.decimal :price, precision: 10, scale: 2
      t.string :delivery_time
      t.boolean :is_active
      t.string :template_name
      t.text :notes

      t.timestamps
    end
  end
end
