class CreateCustomerFormats < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_formats do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :pattern
      t.decimal :quantity
      t.references :product, null: false, foreign_key: true
      t.references :delivery_person, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
