class AddMissingColumnsToLeads < ActiveRecord::Migration[8.0]
  def change
    # Create leads table if it doesn't exist
    unless table_exists?(:leads)
      create_table :leads do |t|
        t.string :name
        t.string :contact_number
        t.string :email
        t.string :current_stage
        t.string :lead_source
        t.timestamps
      end
    end

    add_column :leads, :product_category, :string unless column_exists?(:leads, :product_category)
    add_column :leads, :product_subcategory, :string unless column_exists?(:leads, :product_subcategory)
    add_column :leads, :customer_type, :string unless column_exists?(:leads, :customer_type)
    add_column :leads, :affiliate_id, :integer unless column_exists?(:leads, :affiliate_id)
    add_column :leads, :is_direct, :boolean unless column_exists?(:leads, :is_direct)
    add_column :leads, :first_name, :string unless column_exists?(:leads, :first_name)
    add_column :leads, :last_name, :string unless column_exists?(:leads, :last_name)
    add_column :leads, :middle_name, :string unless column_exists?(:leads, :middle_name)
    add_column :leads, :company_name, :string unless column_exists?(:leads, :company_name)
    add_column :leads, :gender, :string unless column_exists?(:leads, :gender)
    add_column :leads, :marital_status, :string unless column_exists?(:leads, :marital_status)
    add_column :leads, :pan_no, :string unless column_exists?(:leads, :pan_no)
    add_column :leads, :gst_no, :string unless column_exists?(:leads, :gst_no)
    add_column :leads, :height, :decimal unless column_exists?(:leads, :height)
    add_column :leads, :weight, :decimal unless column_exists?(:leads, :weight)
    add_column :leads, :annual_income, :decimal unless column_exists?(:leads, :annual_income)
    add_column :leads, :business_job, :string unless column_exists?(:leads, :business_job)
  end
end
