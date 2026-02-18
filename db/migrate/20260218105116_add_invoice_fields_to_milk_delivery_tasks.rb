class AddInvoiceFieldsToMilkDeliveryTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :milk_delivery_tasks, :invoiced, :boolean, default: false
    add_column :milk_delivery_tasks, :invoiced_at, :datetime
  end
end
