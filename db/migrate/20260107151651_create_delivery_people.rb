class CreateDeliveryPeople < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_people do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :mobile
      t.string :vehicle_type
      t.string :vehicle_number
      t.string :license_number
      t.text :address
      t.string :city
      t.string :state
      t.string :pincode
      t.string :emergency_contact_name
      t.string :emergency_contact_mobile
      t.date :joining_date
      t.decimal :salary
      t.boolean :status
      t.string :profile_picture
      t.string :bank_name
      t.string :account_no
      t.string :ifsc_code
      t.string :account_holder_name
      t.text :delivery_areas
      t.text :notes

      t.timestamps
    end
  end
end
