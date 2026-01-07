#!/usr/bin/env ruby

require 'jwt'

# Test JWT encoding and decoding
token = "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0LCJyb2xlIjoiY3VzdG9tZXIiLCJleHAiOjE3Njc3NjAxODh9.0CuvSpV7l3iq0vCrqiGFwO8Ykv8qKW-rCbqgYWE1oUc"

puts "Token: #{token}"

# Try to decode with same key that would be used in Rails
begin
  decoded_token = JWT.decode(token, "your_secret_key_here")[0]
  puts "Decoded token: #{decoded_token}"
rescue JWT::DecodeError => e
  puts "JWT Decode Error: #{e.message}"
end

# Try to decode with empty key
begin
  decoded_token = JWT.decode(token, nil)[0]
  puts "Decoded token with nil key: #{decoded_token}"
rescue JWT::DecodeError => e
  puts "JWT Decode Error with nil key: #{e.message}"
end

# Try without verification
begin
  decoded_token = JWT.decode(token, nil, false)[0]
  puts "Decoded token without verification: #{decoded_token}"
rescue JWT::DecodeError => e
  puts "JWT Decode Error without verification: #{e.message}"
end