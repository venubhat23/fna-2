class AddMissingColumnsToLeads < ActiveRecord::Migration[8.0]
  def change
    add_column :leads, :product_category, :string
    add_column :leads, :product_subcategory, :string
    add_column :leads, :customer_type, :string
    add_column :leads, :affiliate_id, :integer
    add_column :leads, :is_direct, :boolean
    add_column :leads, :first_name, :string
    add_column :leads, :last_name, :string
    add_column :leads, :middle_name, :string
    add_column :leads, :company_name, :string
    add_column :leads, :gender, :string
    add_column :leads, :marital_status, :string
    add_column :leads, :pan_no, :string
    add_column :leads, :gst_no, :string
    add_column :leads, :height, :decimal
    add_column :leads, :weight, :decimal
    add_column :leads, :annual_income, :decimal
    add_column :leads, :business_job, :string
  end
end
