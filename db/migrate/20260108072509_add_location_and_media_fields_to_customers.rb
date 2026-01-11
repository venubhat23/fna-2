class AddLocationAndMediaFieldsToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :longitude, :decimal, precision: 10, scale: 8
    add_column :customers, :latitude, :decimal, precision: 10, scale: 8
    add_column :customers, :whatsapp_number, :string
    add_column :customers, :auto_generated_password, :string
    add_column :customers, :location_obtained_at, :datetime
    add_column :customers, :location_accuracy, :decimal, precision: 8, scale: 2

    # Add indexes for location-based queries
    add_index :customers, [:latitude, :longitude], name: 'index_customers_on_location'
    add_index :customers, :whatsapp_number
  end
end
