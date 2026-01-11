class AddOccasionalProductFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :is_occasional_product, :boolean, default: false, null: false
    add_column :products, :occasional_start_date, :datetime
    add_column :products, :occasional_end_date, :datetime
    add_column :products, :occasional_description, :text
    add_column :products, :occasional_auto_hide, :boolean, default: true, null: false

    # Add indexes for better performance on occasional product queries
    add_index :products, :is_occasional_product
    add_index :products, [:is_occasional_product, :occasional_start_date, :occasional_end_date],
              name: 'index_products_on_occasional_dates'
  end
end
