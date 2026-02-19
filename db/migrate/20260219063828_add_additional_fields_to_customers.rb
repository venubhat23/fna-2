class AddAdditionalFieldsToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :birth_date, :date
    add_column :customers, :gender, :string
    add_column :customers, :marital_status, :string
    add_column :customers, :pan_no, :string
    add_column :customers, :gst_no, :string
    add_column :customers, :company_name, :string
    add_column :customers, :occupation, :string
    add_column :customers, :annual_income, :decimal
    add_column :customers, :emergency_contact_name, :string
    add_column :customers, :emergency_contact_number, :string
    add_column :customers, :blood_group, :string
    add_column :customers, :nationality, :string
    add_column :customers, :preferred_language, :string
    add_column :customers, :notes, :text
  end
end
