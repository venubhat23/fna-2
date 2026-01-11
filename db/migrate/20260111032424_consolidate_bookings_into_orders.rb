class ConsolidateBookingsIntoOrders < ActiveRecord::Migration[8.0]
  def change
    # Add booking-specific fields to orders table
    add_column :orders, :invoice_generated, :boolean, default: false
    add_column :orders, :invoice_number, :string
    add_column :orders, :cash_received, :decimal, precision: 10, scale: 2
    add_column :orders, :change_amount, :decimal, precision: 10, scale: 2
    add_column :orders, :order_stage, :string, default: 'draft' # draft, confirmed, processing, packed, shipped, out_for_delivery, delivered, cancelled, returned
    add_column :orders, :booking_date, :datetime # For when order was initially created as booking

    # Remove booking_id since we're consolidating
    remove_column :orders, :booking_id, :integer if column_exists?(:orders, :booking_id)

    # Update status to be more comprehensive
    # Will handle this in the model with enhanced enum
  end
end
