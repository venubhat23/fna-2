class AddInvoiceGeneratedToVendorPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :vendor_purchases, :invoice_generated, :boolean, default: false
  end
end
