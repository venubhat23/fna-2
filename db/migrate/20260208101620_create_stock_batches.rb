class CreateStockBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_batches do |t|
      t.references :product, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: true
      t.references :vendor_purchase, null: false, foreign_key: true
      t.decimal :quantity_purchased
      t.decimal :quantity_remaining
      t.decimal :purchase_price
      t.decimal :selling_price
      t.date :batch_date
      t.string :status

      t.timestamps
    end
  end
end
