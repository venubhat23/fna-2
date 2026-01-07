# Create SubAgent User with password first
begin
  sub_agent_user = User.create!(
    first_name: 'TestSub',
    last_name: 'Agent',
    email: 'testsub.agent@example.com',
    password: 'subagent123',
    mobile: '9876543210',
    user_type: 'sub_agent',
    role: 'agent_role',
    status: true
  )
  puts "✅ SubAgent User created with password!"
  puts "SubAgent Login Details:"
  puts "Email: #{sub_agent_user.email}"
  puts "Password: subagent123"
  puts "ID: #{sub_agent_user.id}"
  puts "User Type: #{sub_agent_user.user_type}"

rescue => e
  puts "SubAgent User creation failed: #{e.message}"
end

# Create SubAgent record (without role_id)
begin
  sub_agent = SubAgent.create!(
    first_name: 'TestSub',
    last_name: 'Agent',
    email: 'testsub.agent@example.com',
    mobile: '9876543210',
    status: 'active'
  )
  puts "✅ SubAgent record created: ID #{sub_agent.id}, Email: #{sub_agent.email}"

rescue => e
  puts "SubAgent creation failed: #{e.message}"
end