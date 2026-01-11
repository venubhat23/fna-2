# Dhanvantri Mobile API Testing Guide

This comprehensive guide provides step-by-step instructions for testing all Dhanvantri Mobile API endpoints using various tools and methods.

## Table of Contents
1. [Testing Tools Setup](#testing-tools-setup)
2. [Environment Configuration](#environment-configuration)
3. [Authentication Testing](#authentication-testing)
4. [API Endpoints Testing](#api-endpoints-testing)
5. [Error Scenarios Testing](#error-scenarios-testing)
6. [Performance Testing](#performance-testing)
7. [Automated Testing](#automated-testing)
8. [Troubleshooting Guide](#troubleshooting-guide)

## Testing Tools Setup

### 1. Postman Setup
1. **Download and Install Postman**
   - Go to https://www.postman.com/downloads/
   - Download the desktop app for your OS
   - Install and create a free account

2. **Import Collection**
   - Open Postman
   - Click "Import" button
   - Choose the file: `Dhanvantri_Mobile_API.postman_collection.json`
   - Click "Import"

3. **Create Environment**
   - Click on "Environments" in left sidebar
   - Click "Create Environment"
   - Name: "Dhanvantri Mobile API - Local"
   - Add variables:
     ```
     Variable: base_url
     Initial Value: http://localhost:3000/api/v1/mobile
     Current Value: http://localhost:3000/api/v1/mobile

     Variable: auth_token
     Initial Value: (leave blank)
     Current Value: (leave blank)

     Variable: test_customer_id
     Initial Value: (leave blank)
     Current Value: (leave blank)

     Variable: test_lead_id
     Initial Value: (leave blank)
     Current Value: (leave blank)
     ```

### 2. cURL Setup
Ensure cURL is installed on your system:
```bash
# Check if cURL is installed
curl --version

# Install cURL (if not installed)
# On Ubuntu/Debian
sudo apt-get install curl

# On macOS
brew install curl

# On Windows - usually comes pre-installed
```

### 3. Rails Server Setup
Ensure your Rails server is running:
```bash
# Start Rails server
cd /home/mahadev-bhat/Desktop/work2/drwise_admin
RAILS_ENV=development bundle exec rails server -p 3000

# Verify server is running
curl http://localhost:3000/up
```

## Environment Configuration

### Local Development Environment
- **Base URL**: `http://localhost:3000/api/v1/mobile`
- **Database**: Development SQLite/PostgreSQL
- **Log Level**: Debug

### Test Credentials
```
Admin User:
Email: admin@drwise.com
Password: admin123456

Agent User:
Email: subagent@drwise.com
Password: subagent123456

Customer User 1:
Email: customer1@example.com
Password: customer123456

Customer User 2:
Email: customer2@example.com
Password: customer123456
```

## Authentication Testing

### Step 1: Test Agent Login

#### Using Postman:
1. Select "Agent Login" from the collection
2. Click "Send"
3. Verify response status is 200
4. Check that `auth_token` environment variable is set automatically
5. Verify response contains user information

#### Using cURL:
```bash
curl -X POST http://localhost:3000/api/v1/mobile/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "subagent@drwise.com",
    "password": "subagent123456"
  }'
```

**Expected Response:**
- Status: 200 OK
- Response includes JWT token
- Token should be valid for subsequent requests

### Step 2: Test Token Validation

#### Using Postman:
1. Run "Get Dashboard Statistics" request
2. Verify it uses the token from login
3. Check response is successful

#### Using cURL:
```bash
# Replace TOKEN with actual token from login response
curl -X GET http://localhost:3000/api/v1/mobile/agent/dashboard \
  -H "Authorization: Bearer TOKEN"
```

### Step 3: Test Invalid Authentication

#### Test Cases:
1. **No Token**: Request without Authorization header
2. **Invalid Token**: Request with malformed token
3. **Expired Token**: Request with expired token
4. **Wrong User Type**: Customer token on agent endpoint

## API Endpoints Testing

### Dashboard Testing

#### Test Case 1: Get Dashboard Statistics
**Steps:**
1. Login as agent
2. Call dashboard endpoint
3. Verify all statistics fields are present
4. Check recent activities array

**Expected Results:**
- agent_info object with name, email, mobile, role
- statistics object with counts and totals
- recent_activities array

**cURL Command:**
```bash
curl -X GET http://localhost:3000/api/v1/mobile/agent/dashboard \
  -H "Authorization: Bearer TOKEN"
```

### Customer Management Testing

#### Test Case 1: Get Customers List
**Steps:**
1. Test without filters
2. Test with 'agent_added' filter
3. Test with 'system_added' filter
4. Test pagination

**cURL Commands:**
```bash
# All customers
curl -X GET "http://localhost:3000/api/v1/mobile/agent/customers?page=1&per_page=5" \
  -H "Authorization: Bearer TOKEN"

# Agent added customers only
curl -X GET "http://localhost:3000/api/v1/mobile/agent/customers?filter=agent_added" \
  -H "Authorization: Bearer TOKEN"

# System added customers only
curl -X GET "http://localhost:3000/api/v1/mobile/agent/customers?filter=system_added" \
  -H "Authorization: Bearer TOKEN"
```

#### Test Case 2: Add Customer - Individual
**Steps:**
1. Prepare valid customer data
2. Send POST request
3. Verify customer is created
4. Check tracking fields (added_by, etc.)

**cURL Command:**
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/customers \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_type": "individual",
    "first_name": "Test",
    "last_name": "Customer",
    "email": "test.customer@example.com",
    "mobile": "9876543999",
    "gender": "Male",
    "birth_date": "1990-05-15",
    "address": "123 Test Street",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560001",
    "pan_no": "ABCDE1234F",
    "occupation": "Software Engineer",
    "annual_income": 1200000,
    "marital_status": "Single"
  }'
```

#### Test Case 3: Add Customer - Corporate
**cURL Command:**
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/customers \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_type": "corporate",
    "first_name": "Corporate",
    "last_name": "Customer",
    "company_name": "Test Corp Pvt Ltd",
    "email": "corporate@testcorp.com",
    "mobile": "9876543998",
    "address": "Corporate Park",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "pan_no": "CORP1234E",
    "gst_no": "27CORP1234E1Z5",
    "occupation": "Business",
    "annual_income": 5000000
  }'
```

### Policy Management Testing

#### Test Case 1: Get Policies List
**Steps:**
1. Test all policies
2. Test health policies only
3. Test life policies only
4. Test with pagination

**cURL Commands:**
```bash
# All policies
curl -X GET "http://localhost:3000/api/v1/mobile/agent/policies?page=1&per_page=10" \
  -H "Authorization: Bearer TOKEN"

# Health policies only
curl -X GET "http://localhost:3000/api/v1/mobile/agent/policies?policy_type=health" \
  -H "Authorization: Bearer TOKEN"

# Life policies only
curl -X GET "http://localhost:3000/api/v1/mobile/agent/policies?policy_type=life" \
  -H "Authorization: Bearer TOKEN"
```

#### Test Case 2: Add Health Policy
**Steps:**
1. Get customer ID from customers list
2. Prepare health policy data
3. Send POST request
4. Verify policy creation

**cURL Command:**
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/policies/health \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": CUSTOMER_ID,
    "policy_holder": "Self",
    "insurance_company_id": 5,
    "policy_type": "individual",
    "insurance_type": "health",
    "plan_name": "Star Family Health Plan",
    "policy_number": "SH2024TEST001",
    "policy_start_date": "2024-12-16",
    "policy_end_date": "2025-12-16",
    "payment_mode": "yearly",
    "sum_insured": 500000,
    "net_premium": 38136,
    "gst_percentage": 18,
    "total_premium": 45000
  }'
```

#### Test Case 3: Add Life Policy
**cURL Command:**
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/policies/life \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": CUSTOMER_ID,
    "policy_holder": "Test Customer",
    "plan_name": "LIC Jeevan Anand",
    "policy_number": "LICTEST001",
    "insurance_company_name": "LIC of India",
    "policy_type": "New",
    "policy_start_date": "2024-12-16",
    "policy_end_date": "2044-12-16",
    "payment_mode": "yearly",
    "policy_term": 20,
    "premium_payment_term": 15,
    "sum_insured": 1000000,
    "net_premium": 50000,
    "total_premium": 59000,
    "nominee_name": "Test Nominee",
    "nominee_relationship": "Spouse",
    "agent_commission_percentage": 5,
    "commission_amount": 2950
  }'
```

### Leads Management Testing

#### Test Case 1: Get Leads List
**Steps:**
1. Test all leads
2. Test filtered by stage
3. Test filtered by product
4. Test search functionality

**cURL Commands:**
```bash
# All leads
curl -X GET "http://localhost:3000/api/v1/mobile/agent/leads?page=1&per_page=10" \
  -H "Authorization: Bearer TOKEN"

# Filter by stage
curl -X GET "http://localhost:3000/api/v1/mobile/agent/leads?stage=consultation" \
  -H "Authorization: Bearer TOKEN"

# Filter by product
curl -X GET "http://localhost:3000/api/v1/mobile/agent/leads?product=health" \
  -H "Authorization: Bearer TOKEN"

# Search leads
curl -X GET "http://localhost:3000/api/v1/mobile/agent/leads?search=Kumar" \
  -H "Authorization: Bearer TOKEN"
```

#### Test Case 2: Add Lead
**cURL Command:**
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/leads \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Lead",
    "contact_number": "9876543000",
    "email": "testlead@example.com",
    "product_interest": "health",
    "address": "Test Address",
    "city": "Mumbai",
    "state": "Maharashtra",
    "referred_by": "Agent",
    "current_stage": "consultation",
    "priority": "high",
    "note": "Interested in family health insurance",
    "lead_source": "agent_referral"
  }'
```

### Insurance Companies Testing

#### Test Case 1: Get Insurance Companies
**Steps:**
1. Test all companies
2. Test active companies only
3. Test search functionality
4. Test pagination

**cURL Commands:**
```bash
# All companies
curl -X GET "http://localhost:3000/api/v1/mobile/agent/insurance_companies?page=1&per_page=20" \
  -H "Authorization: Bearer TOKEN"

# Active companies only
curl -X GET "http://localhost:3000/api/v1/mobile/agent/insurance_companies?status=active" \
  -H "Authorization: Bearer TOKEN"

# Search companies
curl -X GET "http://localhost:3000/api/v1/mobile/agent/insurance_companies?search=LIC" \
  -H "Authorization: Bearer TOKEN"
```

### Form Data Testing

#### Test Case 1: Get Form Data
**cURL Command:**
```bash
curl -X GET http://localhost:3000/api/v1/mobile/agent/form_data \
  -H "Authorization: Bearer TOKEN"
```

**Expected Response Structure:**
- clients array
- insurance_companies array
- payment_modes array
- policy_types array
- lead_stages array
- lead_sources array
- product_interests array
- priority_levels array
- states array
- customer_types array
- genders array
- marital_statuses array
- vehicle_types array
- coverage_types array

## Error Scenarios Testing

### 1. Authentication Errors

#### Test Invalid Credentials:
```bash
curl -X POST http://localhost:3000/api/v1/mobile/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "wrong@email.com",
    "password": "wrongpassword"
  }'
```
**Expected**: 401 Unauthorized

#### Test Missing Token:
```bash
curl -X GET http://localhost:3000/api/v1/mobile/agent/dashboard
```
**Expected**: 401 Unauthorized with message "Authorization token is required"

#### Test Invalid Token:
```bash
curl -X GET http://localhost:3000/api/v1/mobile/agent/dashboard \
  -H "Authorization: Bearer invalid_token"
```
**Expected**: 401 Unauthorized with message "Invalid authorization token"

### 2. Validation Errors

#### Test Customer Creation with Missing Fields:
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/customers \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "",
    "email": "invalid-email",
    "mobile": "123"
  }'
```
**Expected**: 422 Unprocessable Entity with validation errors

#### Test Duplicate Customer:
```bash
# Create customer first, then try to create same customer again
curl -X POST http://localhost:3000/api/v1/mobile/agent/customers \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_type": "individual",
    "first_name": "Duplicate",
    "last_name": "Customer",
    "email": "existing@email.com",
    "mobile": "9876543211"
  }'
```
**Expected**: 422 Unprocessable Entity with duplicate error

### 3. Not Found Errors

#### Test Policy Creation with Invalid Customer:
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/policies/health \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": 99999,
    "policy_holder": "Test",
    "insurance_company_id": 1,
    "plan_name": "Test Plan",
    "policy_number": "TEST001",
    "net_premium": 10000
  }'
```
**Expected**: 404 Not Found with message "Customer not found"

## Performance Testing

### 1. Response Time Testing

#### Using cURL to measure response times:
```bash
# Test dashboard endpoint response time
curl -w "@curl-format.txt" -o /dev/null -s \
  -X GET http://localhost:3000/api/v1/mobile/agent/dashboard \
  -H "Authorization: Bearer TOKEN"
```

Create `curl-format.txt` file:
```
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
```

### 2. Load Testing with Postman

#### Setup Collection Runner:
1. Open Postman Collection Runner
2. Select "Dhanvantri Mobile API" collection
3. Set iterations: 10
4. Set delay: 100ms
5. Run collection

#### Benchmark Targets:
- Dashboard: < 500ms
- Customer List: < 1000ms
- Policy Creation: < 2000ms
- Lead Creation: < 800ms

### 3. Concurrent User Testing

#### Bash Script for Load Testing:
```bash
#!/bin/bash
# load_test.sh

TOKEN="your_token_here"
BASE_URL="http://localhost:3000/api/v1/mobile"

# Function to test dashboard
test_dashboard() {
  curl -s -w "%{time_total}\n" -o /dev/null \
    -X GET "$BASE_URL/agent/dashboard" \
    -H "Authorization: Bearer $TOKEN"
}

# Run 10 concurrent requests
for i in {1..10}; do
  test_dashboard &
done
wait

echo "Load test completed"
```

## Automated Testing

### 1. Postman Test Scripts

#### Global Test Script (Collection Level):
```javascript
// Add to Collection > Tests tab
pm.test("Response time is less than 5000ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(5000);
});

pm.test("Response has proper headers", function () {
    pm.expect(pm.response.headers.get("Content-Type")).to.include("application/json");
});

pm.test("No server errors", function () {
    pm.expect(pm.response.code).to.not.be.oneOf([500, 502, 503, 504]);
});
```

#### Login Test Script:
```javascript
// Add to Agent Login > Tests tab
pm.test("Login successful", function () {
    pm.response.to.have.status(200);

    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('success', true);
    pm.expect(jsonData.data).to.have.property('token');

    // Save token for subsequent requests
    pm.environment.set("auth_token", jsonData.data.token);
    pm.environment.set("user_id", jsonData.data.user.id);
});
```

#### Customer Creation Test Script:
```javascript
// Add to Add Customer > Tests tab
pm.test("Customer created successfully", function () {
    pm.response.to.have.status(201);

    const jsonData = pm.response.json();
    pm.expect(jsonData.status).to.be.true;
    pm.expect(jsonData.data).to.have.property('customer_id');

    // Save customer ID for policy creation
    pm.environment.set("test_customer_id", jsonData.data.customer_id);
});

pm.test("Customer has proper agent tracking", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.added_by).to.include('agent_mobile_api_');
    pm.expect(jsonData.data.added_by_agent).to.have.property('id');
});
```

### 2. Running Automated Tests

#### Command Line Collection Runner:
```bash
# Install Newman (Postman CLI)
npm install -g newman

# Run collection
newman run Dhanvantri_Mobile_API.postman_collection.json \
  -e Dhanvantri_Mobile_API_Local.postman_environment.json \
  --reporters cli,html \
  --reporter-html-export test-results.html
```

#### Continuous Integration (GitHub Actions):
```yaml
# .github/workflows/api-tests.yml
name: API Tests
on: [push, pull_request]

jobs:
  api-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0
          bundler-cache: true

      - name: Setup Database
        run: |
          bundle exec rails db:create
          bundle exec rails db:migrate
          bundle exec rails db:seed

      - name: Start Rails Server
        run: bundle exec rails server -d -p 3000

      - name: Wait for Server
        run: sleep 10

      - name: Install Newman
        run: npm install -g newman

      - name: Run API Tests
        run: |
          newman run Dhanvantri_Mobile_API.postman_collection.json \
            -e Dhanvantri_Mobile_API_Local.postman_environment.json \
            --reporters cli,junit \
            --reporter-junit-export results.xml
```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Server Not Running
**Error**: "Connection refused" or "ECONNREFUSED"
**Solution**:
```bash
# Check if server is running
curl http://localhost:3000/up

# If not running, start server
RAILS_ENV=development bundle exec rails server -p 3000
```

#### 2. Authentication Issues
**Error**: "Authorization token is required"
**Solution**:
1. Ensure you've logged in first
2. Check that token is saved in environment variables
3. Verify Authorization header format: `Bearer {token}`

#### 3. Database Issues
**Error**: Database-related errors
**Solution**:
```bash
# Reset database
bundle exec rails db:drop
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

# Or run mock data script
RAILS_ENV=development bundle exec rails runner create_mock_data.rb
```

#### 4. Validation Errors
**Error**: 422 Unprocessable Entity
**Solution**:
1. Check request body format
2. Verify required fields are present
3. Ensure data types match expectations
4. Check for duplicate constraints

#### 5. Token Expiration
**Error**: "Invalid authorization token"
**Solution**:
1. Re-login to get new token
2. Update environment variable with new token

### Debugging Tips

#### 1. Enable Rails Debug Mode
```bash
# Check Rails logs
tail -f log/development.log

# Run with verbose logging
RAILS_ENV=development bundle exec rails server -p 3000 --verbose
```

#### 2. Use Postman Console
1. Open Postman Console (View > Show Postman Console)
2. Monitor request/response details
3. Check for hidden characters or formatting issues

#### 3. Validate JSON Payloads
```bash
# Use jq to validate JSON
echo '{"key": "value"}' | jq .

# Or use online JSON validators
```

#### 4. Network Debugging
```bash
# Check network connectivity
ping localhost

# Check port availability
netstat -an | grep 3000

# Test with telnet
telnet localhost 3000
```

### Testing Checklist

#### Before Testing:
- [ ] Rails server is running on port 3000
- [ ] Database is migrated and seeded
- [ ] Mock data is created
- [ ] Test users exist
- [ ] Environment variables are set

#### During Testing:
- [ ] Test happy path scenarios first
- [ ] Test edge cases and error scenarios
- [ ] Verify response formats match documentation
- [ ] Check pagination works correctly
- [ ] Validate filtering and searching
- [ ] Test file uploads (if applicable)
- [ ] Verify authentication and authorization

#### After Testing:
- [ ] Document any issues found
- [ ] Update test cases if needed
- [ ] Clean up test data
- [ ] Review performance metrics
- [ ] Update documentation if APIs changed

---

This testing guide provides comprehensive coverage for testing the Dhanvantri Mobile API. Follow the steps systematically to ensure all endpoints work correctly and handle error cases appropriately.