class MakeVendorPurchaseOptionalInStockBatches < ActiveRecord::Migration[8.0]
  def change
    change_column_null :stock_batches, :vendor_purchase_id, true
  end
end
