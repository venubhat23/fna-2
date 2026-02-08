class CreateVendorPurchaseItems < ActiveRecord::Migration[8.0]
  def change
    create_table :vendor_purchase_items do |t|
      t.references :vendor_purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity
      t.decimal :purchase_price
      t.decimal :selling_price
      t.decimal :line_total

      t.timestamps
    end
  end
end
