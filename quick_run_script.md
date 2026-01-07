# Quick Script Execution Guide

## Option 1: Run the Complete Script File (Recommended)

1. **Open Rails Console:**
   ```bash
   cd /path/to/insurebook_admin
   rails console
   ```

2. **Load and Execute the Script:**
   ```ruby
   load Rails.root.join('generate_mock_data.rb')
   ```

## Option 2: Copy-Paste One-Liner

If you prefer to copy-paste directly into Rails console:

```ruby
# One-line script execution
eval(File.read(Rails.root.join('generate_mock_data.rb')))
```

## Option 3: Download and Run

1. Download the script file to your project root
2. Open Rails console: `rails c`
3. Run: `load 'generate_mock_data.rb'`

## What the Script Creates:

### Users & Agents (5 total)
- 1 Admin user
- 2 Agent users
- 2 Sub agents

### Companies & Agencies
- 6 Insurance companies
- 1 Broker
- 1 Agency code

### Customers (7 total)
- 5 Individual customers
- 2 Corporate customers
- 6 Family members

### Insurance Policies (10 total)
- 3 Health insurance policies
- 3 Life insurance policies
- 2 Motor insurance policies
- 2 Other insurance policies

### Total Premium Value: ₹1,60,000
### Total Commission: ₹24,750

## Login Credentials for API Testing:

### Admin/Agents:
```
admin@example.com / password123
agent1@example.com / password123
agent2@example.com / password123
```

### Sub Agents:
```
rakesh.agent@example.com / password123
priya.agent@example.com / password123
```

### Customers:
```
rajesh.kumar@example.com / password123
priya.sharma@example.com / password123
amit.patel@example.com / password123
suresh.reddy@example.com / password123
anita.singh@example.com / password123
```

## Verification Commands:

After running the script, verify the data:

```ruby
# Check counts
puts "Users: #{User.count}"
puts "Customers: #{Customer.count}"
puts "Health Policies: #{HealthInsurance.count}"
puts "Life Policies: #{LifeInsurance.count}"
puts "Motor Policies: #{Policy.where(insurance_type: 'motor').count}"
puts "Other Policies: #{Policy.where(insurance_type: 'other').count}"

# Check totals
puts "Total Premium: ₹#{(HealthInsurance.sum(:total_premium) + LifeInsurance.sum(:total_premium) + Policy.sum(:total_premium)).to_i}"
```

## API Testing Ready!

Once the script completes successfully:
1. Import the Postman collection
2. Use any of the login credentials above
3. Test all 25 mobile API endpoints
4. All endpoints will return realistic data!

**Execution time: ~10-30 seconds**