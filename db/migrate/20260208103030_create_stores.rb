class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table :stores do |t|
      t.string :name
      t.text :description
      t.text :address
      t.string :city
      t.string :state
      t.string :pincode
      t.string :contact_person
      t.string :contact_mobile
      t.string :email
      t.boolean :status
      t.string :gst_no

      t.timestamps
    end
  end
end
