class CreateDeliveryRules < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_rules do |t|
      t.references :product, null: false, foreign_key: true
      t.string :rule_type, null: false # 'all', 'state', 'city', 'pincode'
      t.text :location_data # JSON data for states/cities/pincodes
      t.boolean :is_excluded, default: false # for exclusion rules
      t.integer :delivery_days # estimated delivery time
      t.decimal :delivery_charge, precision: 8, scale: 2, default: 0

      t.timestamps
    end

    add_index :delivery_rules, :rule_type
  end
end
