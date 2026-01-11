class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    # Add missing fields to existing users table
    add_column :users, :middle_name, :string unless column_exists?(:users, :middle_name)
    add_column :users, :password_digest, :string unless column_exists?(:users, :password_digest)
    add_column :users, :user_type, :string, default: 'admin' unless column_exists?(:users, :user_type)
    add_column :users, :role, :string, default: 'super_admin' unless column_exists?(:users, :role)
    add_column :users, :role_id, :integer unless column_exists?(:users, :role_id)
    add_column :users, :status, :boolean, default: true unless column_exists?(:users, :status)
    add_column :users, :is_active, :boolean, default: true unless column_exists?(:users, :is_active)
    add_column :users, :is_verified, :boolean, default: false unless column_exists?(:users, :is_verified)

    # Personal Information
    add_column :users, :birth_date, :date unless column_exists?(:users, :birth_date)
    add_column :users, :gender, :string unless column_exists?(:users, :gender)
    add_column :users, :pan_no, :string unless column_exists?(:users, :pan_no)
    add_column :users, :aadhar_no, :string unless column_exists?(:users, :aadhar_no)
    add_column :users, :gst_no, :string unless column_exists?(:users, :gst_no)

    # Company Information
    add_column :users, :company_name, :string unless column_exists?(:users, :company_name)
    add_column :users, :address, :text unless column_exists?(:users, :address)
    add_column :users, :city, :string unless column_exists?(:users, :city)
    add_column :users, :state, :string unless column_exists?(:users, :state)
    add_column :users, :pincode, :string unless column_exists?(:users, :pincode)
    add_column :users, :country, :string, default: 'India' unless column_exists?(:users, :country)

    # Profile
    add_column :users, :profile_picture, :string unless column_exists?(:users, :profile_picture)

    # Banking Information
    add_column :users, :bank_name, :string unless column_exists?(:users, :bank_name)
    add_column :users, :account_no, :string unless column_exists?(:users, :account_no)
    add_column :users, :ifsc_code, :string unless column_exists?(:users, :ifsc_code)
    add_column :users, :account_holder_name, :string unless column_exists?(:users, :account_holder_name)
    add_column :users, :account_type, :string unless column_exists?(:users, :account_type)
    add_column :users, :upi_id, :string unless column_exists?(:users, :upi_id)

    # Emergency Contact
    add_column :users, :emergency_contact_name, :string unless column_exists?(:users, :emergency_contact_name)
    add_column :users, :emergency_contact_mobile, :string unless column_exists?(:users, :emergency_contact_mobile)

    # Employment Information
    add_column :users, :department, :string unless column_exists?(:users, :department)
    add_column :users, :designation, :string unless column_exists?(:users, :designation)
    add_column :users, :joining_date, :date unless column_exists?(:users, :joining_date)
    add_column :users, :salary, :decimal, precision: 10, scale: 2 unless column_exists?(:users, :salary)
    add_column :users, :employee_id, :string unless column_exists?(:users, :employee_id)
    add_column :users, :reporting_manager_id, :integer unless column_exists?(:users, :reporting_manager_id)

    # Permissions and Access
    add_column :users, :permissions, :text unless column_exists?(:users, :permissions)
    add_column :users, :sidebar_permissions, :text unless column_exists?(:users, :sidebar_permissions)

    # Authentication and Security
    add_column :users, :last_login_at, :datetime unless column_exists?(:users, :last_login_at)
    add_column :users, :login_count, :integer, default: 0 unless column_exists?(:users, :login_count)
    add_column :users, :email_verified_at, :datetime unless column_exists?(:users, :email_verified_at)
    add_column :users, :mobile_verified_at, :datetime unless column_exists?(:users, :mobile_verified_at)
    add_column :users, :two_factor_enabled, :boolean, default: false unless column_exists?(:users, :two_factor_enabled)

    # Password Reset
    add_column :users, :reset_password_token, :string unless column_exists?(:users, :reset_password_token)
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)
    add_column :users, :remember_created_at, :datetime unless column_exists?(:users, :remember_created_at)

    # Session Tracking
    add_column :users, :sign_in_count, :integer, default: 0 unless column_exists?(:users, :sign_in_count)
    add_column :users, :current_sign_in_at, :datetime unless column_exists?(:users, :current_sign_in_at)
    add_column :users, :last_sign_in_at, :datetime unless column_exists?(:users, :last_sign_in_at)
    add_column :users, :current_sign_in_ip, :string unless column_exists?(:users, :current_sign_in_ip)
    add_column :users, :last_sign_in_ip, :string unless column_exists?(:users, :last_sign_in_ip)

    # Email Confirmation
    add_column :users, :confirmation_token, :string unless column_exists?(:users, :confirmation_token)
    add_column :users, :confirmed_at, :datetime unless column_exists?(:users, :confirmed_at)
    add_column :users, :confirmation_sent_at, :datetime unless column_exists?(:users, :confirmation_sent_at)

    # Account Locking
    add_column :users, :unlock_token, :string unless column_exists?(:users, :unlock_token)
    add_column :users, :locked_at, :datetime unless column_exists?(:users, :locked_at)
    add_column :users, :failed_attempts, :integer, default: 0 unless column_exists?(:users, :failed_attempts)

    # Additional Information
    add_column :users, :notes, :text unless column_exists?(:users, :notes)
    add_column :users, :created_by, :integer unless column_exists?(:users, :created_by)
    add_column :users, :updated_by, :integer unless column_exists?(:users, :updated_by)
    add_column :users, :deleted_at, :datetime unless column_exists?(:users, :deleted_at)

    # Add indexes for performance (only if they don't exist)
    add_index :users, :mobile, unique: true unless index_exists?(:users, :mobile)
    add_index :users, :pan_no, unique: true unless index_exists?(:users, :pan_no)
    add_index :users, :aadhar_no, unique: true unless index_exists?(:users, :aadhar_no)
    add_index :users, :employee_id, unique: true unless index_exists?(:users, :employee_id)
    add_index :users, :user_type unless index_exists?(:users, :user_type)
    add_index :users, :role unless index_exists?(:users, :role)
    add_index :users, :status unless index_exists?(:users, :status)
    add_index :users, :is_active unless index_exists?(:users, :is_active)
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
    add_index :users, :confirmation_token, unique: true unless index_exists?(:users, :confirmation_token)
    add_index :users, :unlock_token, unique: true unless index_exists?(:users, :unlock_token)
    add_index :users, :deleted_at unless index_exists?(:users, :deleted_at)
  end
end
