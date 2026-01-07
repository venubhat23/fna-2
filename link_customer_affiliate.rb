# Script to link Ram Bhat customer to test 5 test 5 affiliate
puts "Linking Ram Bhat customer to test 5 test 5 affiliate..."

# Find Ram Bhat customer
ram_customer = Customer.where("LOWER(first_name || ' ' || last_name) LIKE ?", "%ram%bhat%").first
if ram_customer.nil?
  puts "❌ Ram Bhat customer not found"
  exit
end

# Find test 5 test 5 affiliate
test_affiliate = SubAgent.where("LOWER(first_name || ' ' || last_name) LIKE ?", "%test%5%").first
if test_affiliate.nil?
  puts "❌ test 5 test 5 affiliate not found"
  exit
end

puts "Found customer: #{ram_customer.first_name} #{ram_customer.last_name} (ID: #{ram_customer.id})"
puts "Found affiliate: #{test_affiliate.first_name} #{test_affiliate.last_name} (ID: #{test_affiliate.id})"

# Link them
ram_customer.sub_agent_id = test_affiliate.id

if ram_customer.save
  puts "✅ Successfully linked #{ram_customer.display_name} to affiliate #{test_affiliate.display_name}"
  puts "Customer ID: #{ram_customer.id}"
  puts "Affiliate ID: #{test_affiliate.id}"
else
  puts "❌ Failed to link: #{ram_customer.errors.full_messages.join(', ')}"
end