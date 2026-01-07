# Customer Password Change Scripts

## Available Scripts

### 1. `change_customer_password.rb` - Full-featured script
Comprehensive script with multiple options for changing customer passwords.

### 2. `quick_customer_password_reset.rb` - Simple reset script
Quick script for basic password reset operations.

## Usage Examples

### Single Customer Password Change

```bash
# Change password by email
RAILS_ENV=development bundle exec rails runner change_customer_password.rb email "customer@example.com" "NewPassword123"

# Change password by mobile number
RAILS_ENV=development bundle exec rails runner change_customer_password.rb mobile "9876543210" "NewPassword123"

# Change password by customer ID
RAILS_ENV=development bundle exec rails runner change_customer_password.rb id "5" "NewPassword123"
```

### Bulk Operations

```bash
# Reset ALL customer passwords (be careful!)
RAILS_ENV=development bundle exec rails runner change_customer_password.rb reset_all "Ganesha@123"

# Bulk change from email list file
RAILS_ENV=development bundle exec rails runner change_customer_password.rb bulk_email "customers_sample.txt" "NewPassword123"
```

### Quick Reset Script

```bash
# Quick reset by any identifier (email/mobile/id)
RAILS_ENV=development bundle exec rails runner quick_customer_password_reset.rb "customer@example.com"

# Quick reset with custom password
RAILS_ENV=development bundle exec rails runner quick_customer_password_reset.rb "9876543210" "CustomPassword"
```

## Script Features

### ✅ `change_customer_password.rb` Features:
- **Multiple search methods**: Email, mobile, customer ID
- **Bulk operations**: Reset all customers or from file
- **User account creation**: Automatically creates User accounts for customers
- **Error handling**: Comprehensive error checking and reporting
- **Confirmation prompts**: Safety confirmations for bulk operations
- **Progress tracking**: Shows success/error counts for bulk operations

### ✅ `quick_customer_password_reset.rb` Features:
- **Smart search**: Automatically detects if input is email, mobile, or ID
- **Simple interface**: Minimal setup required
- **Quick execution**: Streamlined for fast password resets
- **Default password**: Uses system default password

## Safety Features

1. **Validation bypass**: Uses `save!(validate: false)` to bypass validation issues
2. **Role assignment**: Automatically assigns customer role if available
3. **Error recovery**: Handles missing email addresses and other common issues
4. **Confirmation prompts**: Asks for confirmation on bulk operations
5. **Detailed logging**: Shows exactly what's happening at each step

## File Formats

### For bulk email operations, create a text file with one email per line:
```
customer1@example.com
customer2@example.com
user@drwise.com
```

## Common Use Cases

### 1. Reset password for a specific customer
```bash
RAILS_ENV=development bundle exec rails runner quick_customer_password_reset.rb "customer@example.com"
```

### 2. Set all customers to default password
```bash
SKIP_CONFIRMATION=true RAILS_ENV=development bundle exec rails runner change_customer_password.rb reset_all "Ganesha@123"
```

### 3. Change password for customer found by mobile
```bash
RAILS_ENV=development bundle exec rails runner change_customer_password.rb mobile "9876543210" "TempPassword123"
```

### 4. Update multiple specific customers
```bash
# First create customers.txt with the email list, then:
RAILS_ENV=development bundle exec rails runner change_customer_password.rb bulk_email "customers.txt" "NewPassword2024"
```

## Notes

- The scripts automatically handle customer-to-user account linking
- If a customer doesn't have a user account, one will be created
- Customer role is automatically assigned if available
- Mobile number search handles various formats (+91, spaces, hyphens)
- Email search is case-insensitive
- All operations are logged with emojis for easy reading

## Troubleshooting

- **"Customer not found"**: Check the email/mobile/ID is correct
- **"No email address"**: Customer must have email to create user account
- **"Failed to create user"**: Check if email is already taken or invalid
- **"Role not found"**: Ensure customer role exists in the database