#!/usr/bin/env ruby

# Test script for the add_policy API with the new product_through_dr field

require 'net/http'
require 'json'
require 'uri'

# Test data with the new field
test_payload = {
  "insurance_type": "health",
  "plan_name": "Preferred Health Plan",
  "sum_insured": 1000000,
  "premium_amount": 25000,
  "insurance_company": "Star Health Insurance",
  "renewal_date": "2025-12-31",
  "family_members": ["Spouse", "Son"],
  "remarks": "Need health insurance for family coverage with individual rooms and cashless facility",
  "product_through_dr": true  # New field - DR wise product
}

puts "Testing add_policy API with product_through_dr field:"
puts "Payload: #{JSON.pretty_generate(test_payload)}"

# Note: This test requires:
# 1. Rails server to be running
# 2. Valid customer authentication
# 3. Migration to be applied
#
# To run this test properly:
# 1. Start Rails server: rails server -p 3000
# 2. Apply migration: rails db:migrate
# 3. Get a valid customer auth token
# 4. Replace BASE_URL and add authentication headers below

BASE_URL = "http://localhost:3000"

uri = URI("#{BASE_URL}/api/v1/mobile/customer/add_policy")
http = Net::HTTP.new(uri.host, uri.port)

request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'
# Add authentication header when testing
# request['Authorization'] = 'Bearer YOUR_CUSTOMER_TOKEN'

request.body = test_payload.to_json

begin
  response = http.request(request)
  puts "\nResponse Status: #{response.code}"
  puts "Response Body: #{JSON.pretty_generate(JSON.parse(response.body))}"
rescue => e
  puts "Error: #{e.message}"
end