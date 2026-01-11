# Sample Client Requests Data for Testing Multi-Stage System

puts "Creating sample client requests data..."

# Create some users for assignment if not already present
admin_user = User.find_or_create_by(email: 'admin@example.com') do |user|
  user.first_name = 'Admin'
  user.last_name = 'User'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.mobile = '9999999999'
  user.user_type = 'admin'
  user.status = true
end

tech_support = User.find_or_create_by(email: 'techsupport@example.com') do |user|
  user.first_name = 'Tech'
  user.last_name = 'Support'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.mobile = '8888888888'
  user.user_type = 'agent'
  user.status = true
end

sales_agent = User.find_or_create_by(email: 'sales@example.com') do |user|
  user.first_name = 'Sales'
  user.last_name = 'Agent'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.mobile = '7777777777'
  user.user_type = 'agent'
  user.status = true
end

# Sample client request data
sample_requests = [
  {
    name: 'Rajesh Kumar',
    email: 'rajesh.kumar@example.com',
    phone_number: '9876543210',
    description: 'Unable to login to the mobile app. Getting "Invalid credentials" error even with correct password. Need immediate assistance.',
    priority: 'high',
    department: 'technical',
    stage: 'investigating',
    assignee: tech_support,
    admin_response: 'Looking into the authentication issue. Checking server logs.',
    estimated_resolution_time: 4.hours.from_now
  },
  {
    name: 'Priya Sharma',
    email: 'priya.sharma@gmail.com',
    phone_number: '9765432109',
    description: 'Payment gateway showing error during checkout. Transaction failed multiple times. Need to complete my insurance purchase urgently.',
    priority: 'urgent',
    department: 'technical',
    stage: 'in_development',
    assignee: tech_support,
    admin_response: 'Payment gateway integration issue identified. Working on fix.',
    estimated_resolution_time: 2.hours.from_now
  },
  {
    name: 'Amit Patel',
    email: 'amit.patel@company.com',
    phone_number: '9654321098',
    description: 'Need information about corporate health insurance plans for 50+ employees. Require customized quote.',
    priority: 'medium',
    department: 'sales',
    stage: 'assigned',
    assignee: sales_agent,
    estimated_resolution_time: 1.day.from_now
  },
  {
    name: 'Sunita Reddy',
    email: 'sunita.reddy@example.com',
    phone_number: '9543210987',
    description: 'Commission payout for last month missing. Expected amount was ₹15,000 but only received ₹10,000.',
    priority: 'high',
    department: 'billing',
    stage: 'awaiting_customer',
    admin_response: 'Please provide policy numbers and payment screenshots for verification.',
    estimated_resolution_time: 6.hours.from_now
  },
  {
    name: 'Vikash Singh',
    email: 'vikash.singh@email.com',
    phone_number: '9432109876',
    description: 'Mobile app crashes when trying to upload documents. Using Android 12, app version 2.1.5.',
    priority: 'medium',
    department: 'technical',
    stage: 'testing',
    assignee: tech_support,
    admin_response: 'Fix implemented for document upload crash. Currently in testing phase.',
    estimated_resolution_time: 3.hours.from_now
  },
  {
    name: 'Meera Joshi',
    email: 'meera.joshi@example.com',
    phone_number: '9321098765',
    description: 'Policy renewal reminder not received via email or SMS. Policy expires in 2 days.',
    priority: 'high',
    department: 'support',
    stage: 'resolved',
    admin_response: 'Notification system updated. Manual renewal reminder sent via email and SMS.',
    resolved_at: 2.hours.ago,
    actual_resolution_time: 2.hours.ago
  },
  {
    name: 'Ravi Gupta',
    email: 'ravi.gupta@domain.com',
    phone_number: '9210987654',
    description: 'Feature request: Add filter option in policy list to sort by expiry date.',
    priority: 'low',
    department: 'technical',
    stage: 'new',
    estimated_resolution_time: 1.week.from_now
  },
  {
    name: 'Anita Devi',
    email: 'anita.devi@example.com',
    phone_number: '9109876543',
    description: 'Duplicate entries in customer database causing confusion in commission calculation.',
    priority: 'medium',
    department: 'operations',
    stage: 'escalated',
    assignee: admin_user,
    admin_response: 'Data cleanup required. Escalated to database administration team.',
    estimated_resolution_time: 2.days.from_now
  },
  {
    name: 'Kiran Shah',
    email: 'kiran.shah@company.in',
    phone_number: '9087654321',
    description: 'Training request for new features in agent portal. Need video tutorials or documentation.',
    priority: 'low',
    department: 'support',
    stage: 'on_hold',
    admin_response: 'Training materials being prepared. On hold pending content creation.',
    estimated_resolution_time: 5.days.from_now
  },
  {
    name: 'Deepak Mishra',
    email: 'deepak.mishra@example.org',
    phone_number: '8976543210',
    description: 'API integration failing for third-party CRM system. Getting 401 unauthorized errors.',
    priority: 'high',
    department: 'technical',
    stage: 'investigating',
    assignee: tech_support,
    admin_response: 'Checking API credentials and access permissions.',
    estimated_resolution_time: 8.hours.from_now
  }
]

# Create the sample requests
created_count = 0

sample_requests.each_with_index do |request_data, index|
  # Create with base data first
  client_request = ClientRequest.create!(
    name: request_data[:name],
    email: request_data[:email],
    phone_number: request_data[:phone_number],
    description: request_data[:description],
    priority: request_data[:priority],
    department: request_data[:department],
    stage: 'new',  # Start with default stage
    submitted_at: (index + 1).days.ago + rand(0..23).hours
  )

  # Update with stage and other data
  client_request.update!(
    stage: request_data[:stage],
    assignee: request_data[:assignee],
    admin_response: request_data[:admin_response],
    estimated_resolution_time: request_data[:estimated_resolution_time],
    resolved_at: request_data[:resolved_at],
    actual_resolution_time: request_data[:actual_resolution_time],
    stage_updated_at: rand(1..6).hours.ago
  )

  # Add stage history for realistic progression
  if request_data[:stage] != 'new'
    stage_transitions = []
    case request_data[:stage]
    when 'assigned'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 4.hours.ago, changed_by: admin_user.id }
      ]
    when 'investigating'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 1.day.ago, changed_by: admin_user.id },
        { from_stage: 'assigned', to_stage: 'investigating', changed_at: 6.hours.ago, changed_by: request_data[:assignee]&.id }
      ]
    when 'awaiting_customer'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 2.days.ago, changed_by: admin_user.id },
        { from_stage: 'assigned', to_stage: 'investigating', changed_at: 1.day.ago, changed_by: request_data[:assignee]&.id },
        { from_stage: 'investigating', to_stage: 'awaiting_customer', changed_at: 4.hours.ago, changed_by: request_data[:assignee]&.id }
      ]
    when 'in_development'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 3.days.ago, changed_by: admin_user.id },
        { from_stage: 'assigned', to_stage: 'investigating', changed_at: 2.days.ago, changed_by: request_data[:assignee]&.id },
        { from_stage: 'investigating', to_stage: 'in_development', changed_at: 1.day.ago, changed_by: request_data[:assignee]&.id }
      ]
    when 'testing'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 4.days.ago, changed_by: admin_user.id },
        { from_stage: 'assigned', to_stage: 'in_development', changed_at: 3.days.ago, changed_by: request_data[:assignee]&.id },
        { from_stage: 'in_development', to_stage: 'testing', changed_at: 1.day.ago, changed_by: request_data[:assignee]&.id }
      ]
    when 'resolved'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 5.days.ago, changed_by: admin_user.id },
        { from_stage: 'assigned', to_stage: 'investigating', changed_at: 4.days.ago, changed_by: tech_support.id },
        { from_stage: 'investigating', to_stage: 'resolved', changed_at: request_data[:resolved_at], changed_by: tech_support.id }
      ]
    when 'escalated'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 3.days.ago, changed_by: sales_agent.id },
        { from_stage: 'assigned', to_stage: 'investigating', changed_at: 2.days.ago, changed_by: sales_agent.id },
        { from_stage: 'investigating', to_stage: 'escalated', changed_at: 1.day.ago, changed_by: sales_agent.id }
      ]
    when 'on_hold'
      stage_transitions = [
        { from_stage: 'new', to_stage: 'assigned', changed_at: 6.days.ago, changed_by: admin_user.id },
        { from_stage: 'assigned', to_stage: 'on_hold', changed_at: 3.days.ago, changed_by: admin_user.id }
      ]
    end

    if stage_transitions.any?
      client_request.update_column(:stage_history, stage_transitions.to_json)
    end
  end

  created_count += 1
  puts "Created client request: #{client_request.ticket_number} - #{client_request.name}"
end

puts "\nSample data creation completed!"
puts "Created #{created_count} client requests with various stages"
puts "Stage distribution:"

ClientRequest::STAGES.each do |stage|
  count = ClientRequest.where(stage: stage).count
  puts "  #{stage.humanize}: #{count} requests"
end

puts "\nPriority distribution:"
ClientRequest::PRIORITIES.each do |priority|
  count = ClientRequest.where(priority: priority).count
  puts "  #{priority.humanize}: #{count} requests"
end

puts "\nDepartment distribution:"
ClientRequest::DEPARTMENTS.each do |department|
  count = ClientRequest.where(department: department).count
  puts "  #{department.humanize}: #{count} requests"
end

puts "\nUser assignments:"
puts "  Assigned to Tech Support: #{ClientRequest.assigned_to(tech_support.id).count}"
puts "  Assigned to Sales Agent: #{ClientRequest.assigned_to(sales_agent.id).count}"
puts "  Assigned to Admin: #{ClientRequest.assigned_to(admin_user.id).count}"
puts "  Unassigned: #{ClientRequest.unassigned.count}"