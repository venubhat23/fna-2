class AddStageToClientRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :client_requests, :stage, :string, default: 'new'
    add_column :client_requests, :stage_updated_at, :datetime
    add_column :client_requests, :stage_history, :text
    add_column :client_requests, :assignee_id, :integer
    add_column :client_requests, :department, :string
    add_column :client_requests, :estimated_resolution_time, :datetime
    add_column :client_requests, :actual_resolution_time, :datetime

    add_index :client_requests, :stage
    add_index :client_requests, :assignee_id
    add_index :client_requests, :department

    add_foreign_key :client_requests, :users, column: :assignee_id
  end
end
