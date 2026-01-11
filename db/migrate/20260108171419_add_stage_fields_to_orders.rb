class AddStageFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :processing_notes, :text
    add_column :orders, :estimated_processing_time, :integer
    add_column :orders, :processing_started_at, :datetime
    add_column :orders, :packed_by, :string
    add_column :orders, :package_weight, :decimal
    add_column :orders, :package_dimensions, :string
    add_column :orders, :packing_notes, :text
    add_column :orders, :packed_at, :datetime
    add_column :orders, :shipping_carrier, :string
    add_column :orders, :estimated_delivery_date, :date
    add_column :orders, :shipping_cost, :decimal
    add_column :orders, :shipping_notes, :text
    add_column :orders, :shipped_at, :datetime
    add_column :orders, :delivered_to, :string
    add_column :orders, :delivery_location, :string
    add_column :orders, :delivery_notes, :text
    add_column :orders, :cancelled_at, :datetime
    add_column :orders, :cancellation_reason, :string
    add_column :orders, :refund_method, :string
    add_column :orders, :refund_amount, :decimal
    add_column :orders, :cancellation_notes, :text
  end
end
