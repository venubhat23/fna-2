class AddMissingFieldsToClientRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :client_requests, :department, :string
    add_column :client_requests, :estimated_resolution_time, :datetime
    add_column :client_requests, :actual_resolution_time, :datetime

    add_index :client_requests, :department
    add_index :client_requests, :estimated_resolution_time
    add_index :client_requests, :assignee_id
  end
end
