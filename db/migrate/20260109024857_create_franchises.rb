class CreateFranchises < ActiveRecord::Migration[8.0]
  def change
    create_table :franchises do |t|
      t.string :name
      t.string :email
      t.string :mobile
      t.string :contact_person_name
      t.string :business_type
      t.text :address
      t.string :city
      t.string :state
      t.string :pincode
      t.string :pan_no
      t.string :gst_no
      t.string :license_no
      t.date :establishment_date
      t.string :territory
      t.decimal :franchise_fee
      t.decimal :commission_percentage
      t.boolean :status
      t.text :notes
      t.string :password_digest
      t.string :auto_generated_password
      t.decimal :longitude
      t.decimal :latitude
      t.string :whatsapp_number
      t.string :profile_image
      t.text :business_documents

      t.timestamps
    end
    add_index :franchises, :email, unique: true
    add_index :franchises, :mobile, unique: true
    add_index :franchises, :pan_no, unique: true
  end
end
