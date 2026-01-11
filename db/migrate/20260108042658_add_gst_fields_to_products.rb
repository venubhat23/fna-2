class AddGstFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :gst_enabled, :boolean, default: false
    add_column :products, :gst_percentage, :decimal, precision: 5, scale: 2
    add_column :products, :cgst_percentage, :decimal, precision: 5, scale: 2
    add_column :products, :sgst_percentage, :decimal, precision: 5, scale: 2
    add_column :products, :igst_percentage, :decimal, precision: 5, scale: 2
    add_column :products, :gst_amount, :decimal, precision: 10, scale: 2
    add_column :products, :cgst_amount, :decimal, precision: 10, scale: 2
    add_column :products, :sgst_amount, :decimal, precision: 10, scale: 2
    add_column :products, :igst_amount, :decimal, precision: 10, scale: 2
    add_column :products, :final_amount_with_gst, :decimal, precision: 10, scale: 2
  end
end
