class AddStageTransitionFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    # Shipping and tracking information
    add_column :bookings, :courier_service, :string
    add_column :bookings, :tracking_number, :string
    add_column :bookings, :shipping_charges, :decimal, precision: 10, scale: 2
    add_column :bookings, :expected_delivery_date, :date

    # Delivery information
    add_column :bookings, :delivery_person, :string
    add_column :bookings, :delivery_contact, :string
    add_column :bookings, :delivered_to, :string
    add_column :bookings, :delivery_time, :datetime
    add_column :bookings, :customer_satisfaction, :integer

    # Processing information
    add_column :bookings, :processing_team, :string
    add_column :bookings, :expected_completion_time, :datetime
    add_column :bookings, :estimated_processing_time, :string
    add_column :bookings, :estimated_delivery_time, :string

    # Package information
    add_column :bookings, :package_weight, :decimal, precision: 8, scale: 2
    add_column :bookings, :package_dimensions, :string
    add_column :bookings, :quality_status, :string

    # Cancellation and return information
    add_column :bookings, :cancellation_reason, :string
    add_column :bookings, :return_reason, :string
    add_column :bookings, :return_condition, :string
    add_column :bookings, :refund_amount, :decimal, precision: 10, scale: 2
    add_column :bookings, :refund_method, :string

    # Stage transition notes and history
    add_column :bookings, :transition_notes, :text
    add_column :bookings, :stage_history, :text # JSON field to store stage transition history
    add_column :bookings, :stage_updated_at, :datetime
    add_column :bookings, :stage_updated_by, :integer # User who updated the stage

    # Add indexes for better performance
    add_index :bookings, :courier_service
    add_index :bookings, :tracking_number
    add_index :bookings, :expected_delivery_date
    add_index :bookings, :delivery_time
    add_index :bookings, :stage_updated_at
    add_index :bookings, :stage_updated_by
  end
end
