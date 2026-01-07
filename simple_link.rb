# Simple script to link customer 1 to affiliate 46 (test 5 test 5)

begin
  customer = Customer.find(1)
  puts "Customer: #{customer.first_name} #{customer.last_name}"

  customer.sub_agent_id = 46
  customer.save!

  puts "✅ Successfully linked customer 1 to affiliate 46"
rescue => e
  puts "❌ Error: #{e.message}"
end