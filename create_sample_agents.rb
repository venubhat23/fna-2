# Sample data for testing agent management functionality
puts "Creating sample agent data..."

# Check User model columns
begin
  puts "User model columns:"
  puts User.column_names.sort
  puts ""
rescue => e
  puts "Error accessing User model: #{e.message}"
  exit
end

# Sample agent data
sample_agents = [
  {
    first_name: "Rajesh",
    last_name: "Kumar",
    email: "rajesh.kumar@drwise.com",
    mobile: "9876543210",
    user_type: "agent",
    role: "agent_role",
    state: "Maharashtra",
    city: "Mumbai",
    date_of_birth: Date.new(1985, 5, 15),
    gender: "male",
    pan_number: "ABCPK1234F",
    gst_number: "27ABCPK1234F1Z1",
    address: "123 Linking Road, Bandra West, Mumbai",
    password: "password123"
  },
  {
    first_name: "Priya",
    last_name: "Sharma",
    email: "priya.sharma@drwise.com",
    mobile: "9876543211",
    user_type: "agent",
    role: "agent_role",
    state: "Delhi",
    city: "New Delhi",
    date_of_birth: Date.new(1990, 8, 22),
    gender: "female",
    pan_number: "DEFPS5678G",
    address: "456 Connaught Place, New Delhi",
    password: "password123"
  },
  {
    first_name: "Amit",
    last_name: "Patel",
    email: "amit.patel@drwise.com",
    mobile: "9876543212",
    user_type: "sub_agent",
    role: "agent_role",
    state: "Gujarat",
    city: "Ahmedabad",
    date_of_birth: Date.new(1992, 12, 10),
    gender: "male",
    pan_number: "GHIAP9876H",
    gst_number: "24GHIAP9876H1Z2",
    address: "789 SG Highway, Ahmedabad",
    password: "password123"
  },
  {
    first_name: "Sneha",
    last_name: "Reddy",
    email: "sneha.reddy@drwise.com",
    mobile: "9876543213",
    user_type: "agent",
    role: "manager",
    state: "Telangana",
    city: "Hyderabad",
    date_of_birth: Date.new(1987, 3, 18),
    gender: "female",
    pan_number: "JKLSR2345I",
    address: "321 HITEC City, Hyderabad",
    password: "password123"
  },
  {
    first_name: "Admin",
    last_name: "User",
    email: "admin@drwise.com",
    mobile: "9876543214",
    user_type: "admin",
    role: "super_admin",
    state: "Karnataka",
    city: "Bangalore",
    date_of_birth: Date.new(1980, 1, 1),
    gender: "male",
    address: "Headquarters, Bangalore",
    password: "admin123"
  }
]

# Check if bank detail fields are available
has_bank_fields = User.column_names.include?('bank_name')

puts "Model capabilities:"
puts "- Has bank detail fields: #{has_bank_fields}"
puts ""

sample_agents.each_with_index do |agent_data, i|
  puts "Creating #{agent_data[:user_type]} #{i + 1}: #{agent_data[:first_name]} #{agent_data[:last_name]}..."

  # Check if user already exists
  existing_user = User.find_by(email: agent_data[:email])
  if existing_user
    puts "  ⚠️  User with email #{agent_data[:email]} already exists, skipping..."
    next
  end

  # Build attributes hash
  attributes = agent_data.dup
  attributes[:status] = true  # Active by default

  # Add bank details if fields exist (for agents)
  if has_bank_fields && ['agent', 'sub_agent'].include?(agent_data[:user_type])
    bank_names = ['State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank', 'Punjab National Bank']

    attributes.merge!({
      bank_name: bank_names[i % bank_names.length],
      account_number: "1234567890#{i}",
      ifsc_code: "SBIN000#{sprintf('%04d', i + 1)}",
      account_holder_name: "#{agent_data[:first_name]} #{agent_data[:last_name]}",
      account_type: ['savings', 'current'][i % 2],
      upi_id: "#{agent_data[:first_name].downcase}#{i}@paytm"
    })
  end

  begin
    user = User.create!(attributes)
    puts "  ✅ Created: #{user.first_name} #{user.last_name} (#{user.user_type})"
    puts "     Email: #{user.email}"
    puts "     Mobile: #{user.mobile}"
    if has_bank_fields && user.bank_name.present?
      puts "     Bank: #{user.bank_name}"
    end
  rescue => e
    puts "  ❌ Failed to create #{agent_data[:first_name]} #{agent_data[:last_name]}: #{e.message}"
    puts "     Errors: #{e.record&.errors&.full_messages&.join(', ') if e.respond_to?(:record)}"
  end

  puts ""
end

puts "🎉 Sample agent data creation completed!"
puts ""
puts "Statistics:"
puts "- Total users: #{User.count}"
puts "- Administrators: #{User.where(user_type: 'admin').count}"
puts "- Agents: #{User.where(user_type: 'agent').count}"
puts "- Sub Agents: #{User.where(user_type: 'sub_agent').count}"
puts "- Active users: #{User.where(status: true).count}"
puts ""
puts "Test Credentials:"
sample_agents.each do |agent|
  puts "- #{agent[:first_name]} #{agent[:last_name]} (#{agent[:user_type]}): #{agent[:email]} / #{agent[:password]}"
end
puts ""
puts "You can now visit /admin/users to see the agent management interface!"