class CreateSystemSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :system_settings do |t|
      t.string :key
      t.text :value
      t.string :setting_type
      t.text :description
      t.decimal :default_main_agent_commission
      t.decimal :default_affiliate_commission
      t.decimal :default_ambassador_commission
      t.decimal :default_company_expenses

      t.timestamps
    end
    add_index :system_settings, :key, unique: true
  end
end
