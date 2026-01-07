# Rails Admin Commands

## Make User Admin via Rails Console

### One-liner command:
```ruby
User.find_by(email: 'newuss1ser@example.com').update!(role: 'admin', user_type: 'admin')
```

### Step by step:
```ruby
# Find the user
user = User.find_by(email: 'newuss1ser@example.com')

# Check current status
puts "Current role: #{user.role}"
puts "Current user type: #{user.user_type}"

# Update to admin
user.update!(role: 'admin', user_type: 'admin')

# Confirm changes
puts "New role: #{user.role}"
puts "New user type: #{user.user_type}"
```

### Via Rails Console Command Line:
```bash
# Run rails console and execute:
rails console -e "User.find_by(email: 'newuss1ser@example.com').update!(role: 'admin', user_type: 'admin'); puts 'User is now admin!'"
```

## Other Useful Commands

### List all users:
```ruby
User.all.each { |u| puts "#{u.email} - #{u.role}/#{u.user_type}" }
```

### Find users by role:
```ruby
User.where(role: 'admin')
User.where(user_type: 'admin')
```

### Make multiple users admin:
```ruby
emails = ['user1@example.com', 'user2@example.com']
emails.each do |email|
  user = User.find_by(email: email)
  user&.update!(role: 'admin', user_type: 'admin')
end
```