# Create client requests with ticket numbers

puts "Dropping and recreating client_requests table to add ticket_number column..."

# First, let's reset the migration and run it again
begin
  # Drop table if it exists
  ActiveRecord::Migration.drop_table :client_requests if ActiveRecord::Base.connection.table_exists?(:client_requests)
  puts "✅ Dropped existing client_requests table"
rescue => e
  puts "Note: #{e.message}"
end

# Run the migration again
begin
  ActiveRecord::Migration.create_table :client_requests do |t|
    t.string :ticket_number, null: false
    t.string :name, null: false
    t.string :email, null: false
    t.string :phone_number, null: false
    t.text :description, null: false
    t.string :status, default: 'pending'
    t.string :priority, default: 'medium'
    t.string :subject
    t.string :request_type
    t.datetime :submitted_at, null: false
    t.text :admin_response
    t.datetime :resolved_at
    t.references :resolved_by, foreign_key: { to_table: :users }, null: true

    t.timestamps
  end

  ActiveRecord::Base.connection.add_index :client_requests, :ticket_number, unique: true
  ActiveRecord::Base.connection.add_index :client_requests, :email
  ActiveRecord::Base.connection.add_index :client_requests, :status
  ActiveRecord::Base.connection.add_index :client_requests, :submitted_at

  puts "✅ Created client_requests table with ticket_number column"
rescue => e
  puts "Error creating table: #{e.message}"
end

# Define the ClientRequest model inline if it doesn't exist
begin
  ClientRequest
rescue NameError
  class ClientRequest < ApplicationRecord
    # Callback to generate ticket number
    before_create :generate_ticket_number

    private

    def generate_ticket_number
      loop do
        # Generate ticket number: TKT-YYYYMMDD-NNNN
        date_part = Date.current.strftime('%Y%m%d')
        random_part = sprintf('%04d', rand(1000..9999))
        self.ticket_number = "TKT-#{date_part}-#{random_part}"
        break unless self.class.exists?(ticket_number: ticket_number)
      end
    end
  end
end

puts "Creating sample client requests with ticket numbers..."

# Sample data with realistic support scenarios
sample_requests = [
  {
    name: "Rajesh Kumar",
    email: "rajesh.kumar@gmail.com",
    phone_number: "9876543210",
    subject: "Health Insurance Premium Increase",
    description: "My health insurance premium has increased by 40% this year. I want to understand the reason and explore other plan options.",
    status: "pending",
    priority: "high",
    request_type: "policy_inquiry",
    submitted_at: 2.days.ago
  },
  {
    name: "Priya Sharma",
    email: "priya.sharma@yahoo.com",
    phone_number: "9876543211",
    subject: "Car Insurance Claim Denial",
    description: "My car accident claim was denied citing 'insufficient evidence'. I have all the required documents and police report.",
    status: "in_progress",
    priority: "urgent",
    request_type: "claim_support",
    submitted_at: 5.days.ago
  },
  {
    name: "Amit Singh",
    email: "amit.singh@outlook.com",
    phone_number: "9876543212",
    subject: "Add Spouse to Life Insurance",
    description: "I got married recently and want to add my wife as a nominee and increase the coverage amount.",
    status: "resolved",
    priority: "medium",
    request_type: "policy_change",
    submitted_at: 7.days.ago,
    resolved_at: 3.days.ago
  },
  {
    name: "Sneha Patel",
    email: "sneha.patel@gmail.com",
    phone_number: "9876543213",
    subject: "Payment Gateway Error",
    description: "Unable to pay my motor insurance premium online. The payment gateway shows 'transaction failed' error repeatedly.",
    status: "pending",
    priority: "medium",
    request_type: "payment_issue",
    submitted_at: 1.day.ago
  },
  {
    name: "Vikram Reddy",
    email: "vikram.reddy@rediffmail.com",
    phone_number: "9876543214",
    subject: "Policy Document Correction",
    description: "My policy document has wrong birth date and address. Need to get it corrected urgently for a visa application.",
    status: "in_progress",
    priority: "urgent",
    request_type: "policy_change",
    submitted_at: 3.days.ago
  },
  {
    name: "Kavita Gupta",
    email: "kavita.gupta@gmail.com",
    phone_number: "9876543215",
    subject: "Health Insurance Comparison",
    description: "I want to compare different health insurance plans before my current policy expires next month.",
    status: "closed",
    priority: "low",
    request_type: "general_inquiry",
    submitted_at: 10.days.ago,
    resolved_at: 8.days.ago
  },
  {
    name: "Arjun Verma",
    email: "arjun.verma@company.com",
    phone_number: "9876543216",
    subject: "Corporate Policy Query",
    description: "Our company wants to switch health insurance provider for 500+ employees. Need detailed quotation and coverage comparison.",
    status: "pending",
    priority: "high",
    request_type: "policy_inquiry",
    submitted_at: 4.days.ago
  },
  {
    name: "Meera Joshi",
    email: "meera.joshi@gmail.com",
    phone_number: "9876543217",
    subject: "Travel Insurance Emergency",
    description: "I need emergency travel insurance for my trip to Europe next week. My original policy was cancelled due to payment issue.",
    status: "resolved",
    priority: "urgent",
    request_type: "policy_inquiry",
    submitted_at: 6.days.ago,
    resolved_at: 5.days.ago
  },
  {
    name: "Rohit Agarwal",
    email: "rohit.agarwal@techfirm.com",
    phone_number: "9876543218",
    subject: "Maternity Benefits Clarification",
    description: "My wife is pregnant and I want to understand what maternity benefits are covered under my current health insurance policy.",
    status: "in_progress",
    priority: "medium",
    request_type: "policy_inquiry",
    submitted_at: 8.days.ago
  },
  {
    name: "Deepika Rao",
    email: "deepika.rao@gmail.com",
    phone_number: "9876543219",
    subject: "Premium Refund Request",
    description: "I cancelled my policy within the free look period but haven't received the refund yet. It's been 3 weeks.",
    status: "pending",
    priority: "high",
    request_type: "payment_issue",
    submitted_at: 1.day.ago
  }
]

# Create the sample requests
created_count = 0
sample_requests.each_with_index do |req_data, i|
  begin
    # Generate unique ticket number
    date_part = req_data[:submitted_at].strftime('%Y%m%d')
    random_part = sprintf('%04d', 1000 + i)  # Use incremental numbers to avoid duplicates
    ticket_number = "TKT-#{date_part}-#{random_part}"

    # Create the request
    client_request = ClientRequest.create!({
      ticket_number: ticket_number,
      name: req_data[:name],
      email: req_data[:email],
      phone_number: req_data[:phone_number],
      subject: req_data[:subject],
      description: req_data[:description],
      status: req_data[:status],
      priority: req_data[:priority],
      request_type: req_data[:request_type],
      submitted_at: req_data[:submitted_at],
      resolved_at: req_data[:resolved_at],
      created_at: req_data[:submitted_at],
      updated_at: req_data[:resolved_at] || req_data[:submitted_at]
    })

    created_count += 1
    puts "✅ Created: #{client_request.ticket_number} - #{client_request.name} (#{client_request.status})"

  rescue => e
    puts "❌ Failed to create request #{i + 1}: #{e.message}"
  end
end

puts ""
puts "🎉 Client request creation completed!"
puts ""
puts "Statistics:"
puts "- Total requests created: #{created_count}"
puts "- Pending: #{ClientRequest.where(status: 'pending').count}"
puts "- In Progress: #{ClientRequest.where(status: 'in_progress').count}"
puts "- Resolved: #{ClientRequest.where(status: 'resolved').count}"
puts "- Closed: #{ClientRequest.where(status: 'closed').count}"
puts ""

# Display some sample ticket numbers
puts "Sample ticket numbers:"
ClientRequest.limit(5).each do |req|
  puts "- #{req.ticket_number}: #{req.name} - #{req.subject}"
end
puts ""
puts "✅ Visit /admin/client_requests to see the updated table with ticket numbers!"