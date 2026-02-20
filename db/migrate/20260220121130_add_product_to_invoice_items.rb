class AddProductToInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :invoice_items, :product, null: false, foreign_key: true
  end
end
