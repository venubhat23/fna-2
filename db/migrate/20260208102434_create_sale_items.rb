class CreateSaleItems < ActiveRecord::Migration[8.0]
  def change
    create_table :sale_items do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :stock_batch, null: false, foreign_key: true
      t.decimal :quantity
      t.decimal :selling_price
      t.decimal :purchase_price
      t.decimal :profit_amount
      t.decimal :line_total

      t.timestamps
    end
  end
end
