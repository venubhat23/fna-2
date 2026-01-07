#!/usr/bin/env ruby
# Simple API test script for the generated customer data

require 'net/http'
require 'json'

BASE_URL = 'http://localhost:3000'

def test_api(method, endpoint, data = nil, auth_token = nil)
  uri = URI("#{BASE_URL}#{endpoint}")

  case method.upcase
  when 'GET'
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
  when 'POST'
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request.body = data.to_json if data
  end

  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{auth_token}" if auth_token

  begin
    response = http.request(request)
    puts "#{method} #{endpoint} - Status: #{response.code}"

    if response.code == '200' || response.code == '201'
      parsed = JSON.parse(response.body)
      puts "  ✓ Success: #{parsed['success'] ? 'true' : 'false'}"
      puts "  Data: #{parsed['data'].keys.join(', ') if parsed['data']}"
      return parsed
    else
      puts "  ✗ Error: #{response.body}"
      return nil
    end
  rescue => e
    puts "  ✗ Connection Error: #{e.message}"
    return nil
  end
end

puts "=== Testing Mobile APIs ==="
puts "Customer: newcustomer@example.com"
puts "Password: password123"
puts

# Test login
puts "1. Testing Customer Login..."
login_data = {
  username: 'newcustomer@example.com',
  password: 'password123'
}

login_response = test_api('POST', '/api/v1/mobile/auth/login', login_data)

if login_response && login_response['success']
  auth_token = login_response['data']['token']
  puts "  ✓ Login successful! Token obtained."
  puts

  # Test customer portfolio
  puts "2. Testing Customer Portfolio..."
  test_api('GET', '/api/v1/mobile/customer/portfolio', nil, auth_token)
  puts

  # Test upcoming installments
  puts "3. Testing Upcoming Installments..."
  test_api('GET', '/api/v1/mobile/customer/upcoming_installments', nil, auth_token)
  puts

  # Test upcoming renewals
  puts "4. Testing Upcoming Renewals..."
  test_api('GET', '/api/v1/mobile/customer/upcoming_renewals', nil, auth_token)
  puts

  # Test profile
  puts "5. Testing Profile..."
  test_api('GET', '/api/v1/mobile/settings/profile', nil, auth_token)
  puts

  # Test add policy request
  puts "6. Testing Add Policy Request..."
  add_policy_data = {
    insurance_type: 'health',
    plan_name: 'Test Health Plan',
    sum_insured: 500000,
    premium_amount: 20000,
    insurance_company: 'Star Health Allied Insurance Co Ltd',
    renewal_date: '2025-12-31',
    family_members: ['Spouse'],
    remarks: 'Test policy request via mobile API'
  }
  test_api('POST', '/api/v1/mobile/customer/add_policy', add_policy_data, auth_token)
  puts

else
  puts "  ✗ Login failed! Cannot test other endpoints."
end

puts "=== API Testing Complete ==="
puts
puts "If you want to test manually:"
puts "1. Start the Rails server: bundle exec rails server"
puts "2. Import the Postman collection: InsureBook_Mobile_API_Complete_Collection.postman_collection.json"
puts "3. Set the environment variables in Postman"
puts "4. Use login to get the token and test other endpoints"