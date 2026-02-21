class AddBusinessDetailsToSystemSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :system_settings, :business_name, :string
    add_column :system_settings, :address, :text
    add_column :system_settings, :mobile, :string
    add_column :system_settings, :email, :string
    add_column :system_settings, :gstin, :string
    add_column :system_settings, :pan_number, :string
    add_column :system_settings, :account_holder_name, :string
    add_column :system_settings, :bank_name, :string
    add_column :system_settings, :account_number, :string
    add_column :system_settings, :ifsc_code, :string
    add_column :system_settings, :upi_id, :string
    add_column :system_settings, :qr_code_path, :string
    add_column :system_settings, :terms_and_conditions, :text
  end
end
