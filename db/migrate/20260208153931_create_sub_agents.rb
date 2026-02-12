class CreateSubAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :sub_agents do |t|
      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :email
      t.string :mobile
      t.string :password_digest
      t.string :plain_password
      t.string :original_password
      t.integer :role_id
      t.string :gender
      t.date :birth_date
      t.string :pan_no
      t.string :aadhar_no
      t.string :gst_no
      t.string :company_name
      t.text :address
      t.string :city
      t.string :state
      t.string :pincode
      t.string :country
      t.string :profile_picture
      t.string :bank_name
      t.string :account_no
      t.string :ifsc_code
      t.string :account_holder_name
      t.string :account_type
      t.string :upi_id
      t.string :emergency_contact_name
      t.string :emergency_contact_mobile
      t.date :joining_date
      t.decimal :salary, precision: 10, scale: 2
      t.text :notes
      t.integer :status, default: 0
      t.integer :distributor_id

      t.timestamps
    end
    add_index :sub_agents, :email, unique: true
    add_index :sub_agents, :mobile, unique: true
    add_index :sub_agents, :pan_no, unique: true
    add_index :sub_agents, :aadhar_no, unique: true
  end
end
