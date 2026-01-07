# Check specific SubAgent
email = "dsn101171@gmail.com"
sa = SubAgent.find_by(email: email)

if sa
  puts "Found SubAgent:"
  puts "  ID: #{sa.id}"
  puts "  Name: #{sa.first_name} #{sa.last_name}"
  puts "  Email: #{sa.email}"
  puts "  Plain Password: #{sa.plain_password}"
  puts "  Can authenticate with 'password123': #{sa.authenticate('password123')}"

  # Try to update password
  sa.password = "password122"
  sa.password_confirmation = "password122"
  sa.plain_password = "password122"

  if sa.save
    puts "\nPassword updated successfully!"
    sa.reload
    puts "New plain_password: #{sa.plain_password}"
  else
    puts "\nFailed to update password: #{sa.errors.full_messages.join(', ')}"
  end
else
  puts "SubAgent not found with email: #{email}"
end