class CreateAffiliates < ActiveRecord::Migration[7.0]
  def change
    create_table :affiliates do |t|
      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :email
      t.string :mobile
      t.text :address
      t.string :city
      t.string :state
      t.string :pincode
      t.string :pan_no
      t.string :gst_no
      t.decimal :commission_percentage, precision: 5, scale: 2
      t.string :bank_name
      t.string :account_no
      t.string :ifsc_code
      t.string :account_holder_name
      t.string :account_type
      t.string :upi_id
      t.boolean :status, default: true
      t.text :notes
      t.string :auto_generated_password
      t.date :joining_date

      t.timestamps
    end

    add_index :affiliates, :email, unique: true
    add_index :affiliates, :mobile, unique: true
  end
end
