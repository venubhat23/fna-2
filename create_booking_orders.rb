puts 'Creating dummy bookings and orders...'

# Get existing data
if defined?(Customer) && Customer.any?
  customers = Customer.limit(5)
  puts "Found #{customers.count} customers"
else
  puts "No customers found, will create bookings without customer associations"
  customers = []
end

if defined?(Product) && Product.any?
  products = Product.limit(10)
  puts "Found #{products.count} products"
else
  puts "No products found, skipping product-related data"
  products = []
end

# Create bookings
puts "\nCreating dummy bookings..."

if defined?(Booking)
  booking_data = [
    {
      booking_number: "BK#{Date.current.strftime('%Y%m%d')}001",
      booking_date: Date.current,
      customer_name: "John Doe",
      customer_email: "john.doe@example.com",
      customer_phone: "9876543301",
      delivery_address: "123 Sample Street, Bangalore",
      status: 'pending',
      payment_method: 'cash',
      payment_status: 'unpaid',
      subtotal: 2500.0,
      tax_amount: 450.0,
      total_amount: 2950.0,
      notes: "First time customer order"
    },
    {
      booking_number: "BK#{Date.current.strftime('%Y%m%d')}002",
      booking_date: 1.day.ago,
      customer_name: "Jane Smith",
      customer_email: "jane.smith@example.com",
      customer_phone: "9876543302",
      delivery_address: "456 Demo Road, Bangalore",
      status: 'confirmed',
      payment_method: 'upi',
      payment_status: 'paid',
      subtotal: 1200.0,
      tax_amount: 216.0,
      total_amount: 1416.0,
      notes: "Express delivery requested",
      cash_received: 1500.0,
      change_amount: 84.0
    },
    {
      booking_number: "BK#{Date.current.strftime('%Y%m%d')}003",
      booking_date: 2.days.ago,
      customer_name: "Robert Johnson",
      customer_email: "robert.johnson@example.com",
      customer_phone: "9876543303",
      delivery_address: "789 Test Lane, Whitefield",
      status: 'processing',
      payment_method: 'card',
      payment_status: 'paid',
      subtotal: 5800.0,
      tax_amount: 1044.0,
      total_amount: 6844.0,
      notes: "Corporate order - priority delivery"
    },
    {
      booking_number: "BK#{Date.current.strftime('%Y%m%d')}004",
      booking_date: 3.days.ago,
      customer_name: "Alice Brown",
      customer_email: "alice.brown@example.com",
      customer_phone: "9876543304",
      delivery_address: "321 Mock Avenue, HSR Layout",
      status: 'completed',
      payment_method: 'cash',
      payment_status: 'paid',
      subtotal: 3200.0,
      tax_amount: 576.0,
      total_amount: 3776.0,
      notes: "Delivered successfully",
      invoice_generated: true,
      invoice_number: "INV#{Date.current.strftime('%Y%m%d')}004"
    },
    {
      booking_number: "BK#{Date.current.strftime('%Y%m%d')}005",
      booking_date: 1.week.ago,
      customer_name: "David Wilson",
      customer_email: "david.wilson@example.com",
      customer_phone: "9876543305",
      delivery_address: "654 Example Street, Electronic City",
      status: 'cancelled',
      payment_method: 'upi',
      payment_status: 'refunded',
      subtotal: 1800.0,
      tax_amount: 324.0,
      total_amount: 2124.0,
      notes: "Customer requested cancellation"
    }
  ]

  booking_data.each do |booking_info|
    if customers.any?
      booking_info[:customer] = customers.sample
      booking_info[:customer_id] = booking_info[:customer].id
    end

    if Booking.where(booking_number: booking_info[:booking_number]).exists?
      puts "Booking #{booking_info[:booking_number]} already exists"
    else
      booking = Booking.create!(booking_info)
      puts "✅ Created booking: #{booking.booking_number} (#{booking.status})"
    end
  end

  puts "\n📋 Bookings created: #{Booking.count}"
else
  puts "❌ Booking model not found"
end

# Create orders
puts "\nCreating dummy orders..."

if defined?(Order)
  order_data = [
    {
      order_number: "ORD#{Date.current.strftime('%Y%m%d')}001",
      order_date: Date.current,
      customer_name: "Sarah Connor",
      customer_email: "sarah.connor@example.com",
      customer_phone: "9876543401",
      delivery_address: "123 Future Street, Bangalore",
      status: 'pending',
      payment_method: 'card',
      payment_status: 'paid',
      subtotal: 15000.0,
      tax_amount: 2700.0,
      total_amount: 17700.0,
      notes: "High-value electronics order"
    },
    {
      order_number: "ORD#{Date.current.strftime('%Y%m%d')}002",
      order_date: 1.day.ago,
      customer_name: "Tony Stark",
      customer_email: "tony.stark@example.com",
      customer_phone: "9876543402",
      delivery_address: "456 Innovation Road, Whitefield",
      status: 'processing',
      payment_method: 'upi',
      payment_status: 'paid',
      subtotal: 8500.0,
      tax_amount: 1530.0,
      total_amount: 10030.0,
      tracking_number: "TRK001234567890",
      notes: "Express processing requested"
    },
    {
      order_number: "ORD#{Date.current.strftime('%Y%m%d')}003",
      order_date: 2.days.ago,
      customer_name: "Bruce Wayne",
      customer_email: "bruce.wayne@example.com",
      customer_phone: "9876543403",
      delivery_address: "789 Gotham Lane, Koramangala",
      status: 'shipped',
      payment_method: 'card',
      payment_status: 'paid',
      subtotal: 12000.0,
      tax_amount: 2160.0,
      total_amount: 14160.0,
      tracking_number: "TRK001234567891",
      notes: "Premium shipping selected"
    },
    {
      order_number: "ORD#{Date.current.strftime('%Y%m%d')}004",
      order_date: 4.days.ago,
      customer_name: "Diana Prince",
      customer_email: "diana.prince@example.com",
      customer_phone: "9876543404",
      delivery_address: "321 Amazon Street, HSR Layout",
      status: 'delivered',
      payment_method: 'cash',
      payment_status: 'paid',
      subtotal: 4500.0,
      tax_amount: 810.0,
      total_amount: 5310.0,
      tracking_number: "TRK001234567892",
      delivered_at: 1.day.ago,
      notes: "Delivered successfully, customer satisfied"
    },
    {
      order_number: "ORD#{Date.current.strftime('%Y%m%d')}005",
      order_date: 1.week.ago,
      customer_name: "Peter Parker",
      customer_email: "peter.parker@example.com",
      customer_phone: "9876543405",
      delivery_address: "654 Web Street, BTM Layout",
      status: 'cancelled',
      payment_method: 'upi',
      payment_status: 'refunded',
      subtotal: 3200.0,
      tax_amount: 576.0,
      total_amount: 3776.0,
      notes: "Order cancelled due to stock unavailability"
    },
    {
      order_number: "ORD#{Date.current.strftime('%Y%m%d')}006",
      order_date: 3.days.ago,
      customer_name: "Clark Kent",
      customer_email: "clark.kent@example.com",
      customer_phone: "9876543406",
      delivery_address: "987 Metropolis Avenue, Indiranagar",
      status: 'delivered',
      payment_method: 'card',
      payment_status: 'paid',
      subtotal: 7800.0,
      tax_amount: 1404.0,
      total_amount: 9204.0,
      tracking_number: "TRK001234567893",
      delivered_at: 1.day.ago,
      notes: "Fast delivery completed"
    }
  ]

  order_data.each do |order_info|
    if customers.any?
      order_info[:customer] = customers.sample
      order_info[:customer_id] = order_info[:customer].id
    end

    if Order.where(order_number: order_info[:order_number]).exists?
      puts "Order #{order_info[:order_number]} already exists"
    else
      order = Order.create!(order_info)
      puts "✅ Created order: #{order.order_number} (#{order.status})"
    end
  end

  puts "\n📦 Orders created: #{Order.count}"
else
  puts "❌ Order model not found"
end

puts "\n🎉 Booking and Order dummy data creation completed!"
puts "📊 Final Summary:"
puts "   Delivery Persons: #{defined?(DeliveryPerson) ? DeliveryPerson.count : 'N/A'}"
puts "   Coupons: #{defined?(Coupon) ? Coupon.count : 'N/A'}"
puts "   Categories: #{defined?(Category) ? Category.count : 'N/A'}"
puts "   Products: #{defined?(Product) ? Product.count : 'N/A'}"
puts "   Bookings: #{defined?(Booking) ? Booking.count : 'N/A'}"
puts "   Orders: #{defined?(Order) ? Order.count : 'N/A'}"
puts "   Customers: #{defined?(Customer) ? Customer.count : 'N/A'}"