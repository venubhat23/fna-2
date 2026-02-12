class AddStageToClientRequests < ActiveRecord::Migration[8.0]
  def change
    # Create client_requests table if it doesn't exist
    unless table_exists?(:client_requests)
      create_table :client_requests do |t|
        t.string :title
        t.text :description
        t.string :status, default: 'pending'
        t.string :priority, default: 'medium'
        t.references :customer, foreign_key: true
        t.timestamps
      end
    end

    add_column :client_requests, :stage, :string, default: 'new' unless column_exists?(:client_requests, :stage)
    add_column :client_requests, :stage_updated_at, :datetime unless column_exists?(:client_requests, :stage_updated_at)
    add_column :client_requests, :stage_history, :text unless column_exists?(:client_requests, :stage_history)
    add_column :client_requests, :assignee_id, :integer unless column_exists?(:client_requests, :assignee_id)
    add_column :client_requests, :department, :string unless column_exists?(:client_requests, :department)
    add_column :client_requests, :estimated_resolution_time, :datetime unless column_exists?(:client_requests, :estimated_resolution_time)
    add_column :client_requests, :actual_resolution_time, :datetime unless column_exists?(:client_requests, :actual_resolution_time)

    add_index :client_requests, :stage unless index_exists?(:client_requests, :stage)
    add_index :client_requests, :assignee_id unless index_exists?(:client_requests, :assignee_id)
    add_index :client_requests, :department unless index_exists?(:client_requests, :department)

    add_foreign_key :client_requests, :users, column: :assignee_id unless foreign_key_exists?(:client_requests, :users, column: :assignee_id)
  end
end
