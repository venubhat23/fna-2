# Test Invoice Generation Script
puts "Testing Invoice Generation Functionality..."
puts "=" * 50

# Get a customer with completed delivery tasks
customer = Customer.first
if customer
  puts "Customer: #{customer.display_name}"

  # Check for completed delivery tasks
  completed_tasks = MilkDeliveryTask.where(
    customer: customer,
    status: 'completed',
    invoiced: false
  )

  puts "Completed uninvoiced tasks: #{completed_tasks.count}"

  if completed_tasks.any?
    # Group by product to show what will be invoiced
    completed_tasks.group_by(&:product).each do |product, tasks|
      total_quantity = tasks.sum(&:quantity)
      unit_price = product.price || 30
      total = total_quantity * unit_price

      puts "\nProduct: #{product.name}"
      puts "  - Deliveries: #{tasks.count}"
      puts "  - Total Quantity: #{total_quantity}"
      puts "  - Unit Price: ₹#{unit_price}"
      puts "  - Total Amount: ₹#{total}"
    end

    puts "\nInvoice can be generated for this customer!"
  else
    puts "No completed uninvoiced tasks found for this customer."

    # Create some test completed tasks
    puts "\nCreating test delivery tasks..."

    product = Product.first
    if product
      3.times do |i|
        task = MilkDeliveryTask.create!(
          customer: customer,
          product: product,
          quantity: 1,
          delivery_date: Date.current - i.days,
          status: 'completed',
          invoiced: false
        )
        puts "Created task for #{task.delivery_date}"
      end

      puts "\nTest tasks created. You can now generate an invoice!"
    else
      puts "No products found. Please create products first."
    end
  end
else
  puts "No customers found in the database."
end

puts "\n" + "=" * 50
puts "Test completed!"