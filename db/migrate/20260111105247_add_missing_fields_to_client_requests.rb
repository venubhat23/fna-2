class AddMissingFieldsToClientRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :client_requests, :department, :string unless column_exists?(:client_requests, :department)
    add_column :client_requests, :estimated_resolution_time, :datetime unless column_exists?(:client_requests, :estimated_resolution_time)
    add_column :client_requests, :actual_resolution_time, :datetime unless column_exists?(:client_requests, :actual_resolution_time)

    add_index :client_requests, :department unless index_exists?(:client_requests, :department)
    add_index :client_requests, :estimated_resolution_time unless index_exists?(:client_requests, :estimated_resolution_time)
    add_index :client_requests, :assignee_id unless index_exists?(:client_requests, :assignee_id)
  end
end
