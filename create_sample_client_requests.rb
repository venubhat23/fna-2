# Sample data for testing client requests table UI
puts "Creating sample client request data..."

# First, let's check what fields the ClientRequest model has
begin
  puts "ClientRequest model columns:"
  puts ClientRequest.column_names.sort
  puts ""
rescue => e
  puts "Error accessing ClientRequest model: #{e.message}"
  puts "The model might not exist or have different structure."
  exit
end

# Create sample client requests with various statuses and priorities
sample_requests = [
  {
    name: "John Smith",
    email: "john.smith@example.com",
    phone_number: "9876543210",
    description: "I need help with my health insurance policy renewal. The premium seems to have increased significantly.",
    status: "pending"
  },
  {
    name: "Sarah Johnson",
    email: "sarah.j@example.com",
    phone_number: "9876543211",
    description: "My car insurance claim was denied. I need assistance understanding why and how to appeal.",
    status: "in_progress"
  },
  {
    name: "Michael Davis",
    email: "michael.davis@example.com",
    phone_number: "9876543212",
    description: "I want to add my wife to my existing life insurance policy. What documents are required?",
    status: "resolved"
  },
  {
    name: "Emma Wilson",
    email: "emma.wilson@example.com",
    phone_number: "9876543213",
    description: "My premium payment failed due to insufficient funds. How can I make a manual payment?",
    status: "pending"
  },
  {
    name: "David Brown",
    email: "david.brown@example.com",
    phone_number: "9876543214",
    description: "I received a policy document with incorrect information. Please help me get this corrected.",
    status: "in_progress"
  },
  {
    name: "Lisa Anderson",
    email: "lisa.anderson@example.com",
    phone_number: "9876543215",
    description: "I want to compare different health insurance plans before renewing. Can someone guide me?",
    status: "closed"
  }
]

# Check if the model has priority field
has_priority = ClientRequest.column_names.include?('priority')
has_subject = ClientRequest.column_names.include?('subject')
has_request_type = ClientRequest.column_names.include?('request_type')

puts "Model capabilities:"
puts "- Has priority field: #{has_priority}"
puts "- Has subject field: #{has_subject}"
puts "- Has request_type field: #{has_request_type}"
puts ""

sample_requests.each_with_index do |req_data, i|
  puts "Creating request #{i + 1}..."

  # Build attributes hash
  attributes = {
    name: req_data[:name],
    email: req_data[:email],
    description: req_data[:description],
    status: req_data[:status],
    created_at: (rand(30) + 1).days.ago
  }

  # Add phone_number if field exists
  attributes[:phone_number] = req_data[:phone_number] if ClientRequest.column_names.include?('phone_number')

  # Add priority if field exists
  if has_priority
    priorities = ['low', 'medium', 'high', 'urgent']
    attributes[:priority] = priorities[i % priorities.length]
  end

  # Add subject if field exists
  if has_subject
    subjects = [
      "Policy Renewal Assistance",
      "Claim Support",
      "Policy Addition Request",
      "Payment Issue",
      "Policy Correction",
      "Plan Comparison"
    ]
    attributes[:subject] = subjects[i % subjects.length]
  end

  # Add request_type if field exists
  if has_request_type
    request_types = [
      "policy_inquiry",
      "claim_support",
      "policy_change",
      "payment_issue",
      "technical_support",
      "general_inquiry"
    ]
    attributes[:request_type] = request_types[i % request_types.length]
  end

  begin
    client_request = ClientRequest.create!(attributes)
    puts "✅ Created: #{client_request.name} - #{client_request.status}"
  rescue => e
    puts "❌ Failed to create request #{i + 1}: #{e.message}"
  end
end

puts ""
puts "🎉 Sample client request data creation completed!"
puts ""
puts "Statistics:"
puts "- Total requests: #{ClientRequest.count}"
puts "- Pending: #{ClientRequest.where(status: 'pending').count}"
puts "- In Progress: #{ClientRequest.where(status: 'in_progress').count}"
puts "- Resolved: #{ClientRequest.where(status: 'resolved').count}"
puts "- Closed: #{ClientRequest.where(status: 'closed').count}"
puts ""
puts "You can now visit /admin/client_requests to see the new table UI!"