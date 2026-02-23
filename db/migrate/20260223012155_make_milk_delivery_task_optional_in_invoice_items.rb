class MakeMilkDeliveryTaskOptionalInInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    change_column_null :invoice_items, :milk_delivery_task_id, true
  end
end
