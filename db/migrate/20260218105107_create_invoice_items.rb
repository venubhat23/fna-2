class CreateInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :milk_delivery_task, null: false, foreign_key: true
      t.text :description
      t.decimal :quantity
      t.decimal :unit_price
      t.decimal :total_amount

      t.timestamps
    end
  end
end
