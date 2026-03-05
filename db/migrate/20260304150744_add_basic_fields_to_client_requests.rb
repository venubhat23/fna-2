class AddBasicFieldsToClientRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :client_requests, :name, :string
    add_column :client_requests, :email, :string
    add_column :client_requests, :phone_number, :string
    add_column :client_requests, :ticket_number, :string
    add_index :client_requests, :ticket_number, unique: true
    add_column :client_requests, :admin_response, :text
    add_column :client_requests, :resolved_by_id, :integer
    add_column :client_requests, :submitted_at, :datetime
    add_column :client_requests, :resolved_at, :datetime
  end
end
