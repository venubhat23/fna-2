class CreateVendors < ActiveRecord::Migration[8.0]
  def change
    create_table :vendors do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.text :address
      t.string :payment_type
      t.decimal :opening_balance
      t.boolean :status

      t.timestamps
    end
  end
end
