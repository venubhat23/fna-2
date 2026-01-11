# Simple Dashboard Sample Data Generation
puts "🌱 Creating sample dashboard data..."

# Create Categories if they don't exist
categories_data = [
  "Grocery & Pantry", "Fresh Vegetables", "Dairy & Milk Products",
  "Fresh Fruits", "Beverages", "Snacks & Branded Foods"
]

categories_data.each_with_index do |name, index|
  Category.find_or_create_by(name: name) do |cat|
    cat.description = "Sample #{name} category"
    cat.status = true
    cat.display_order = index + 1
  end
end

puts "✅ Created #{Category.count} categories"

# Create Products if they don't exist
products_data = [
  { name: "Basmati Rice 5kg", category: "Grocery & Pantry", price: 450, stock: 150 },
  { name: "Tomatoes 1kg", category: "Fresh Vegetables", price: 35, stock: 80 },
  { name: "Full Cream Milk 1L", category: "Dairy & Milk Products", price: 68, stock: 50 },
  { name: "Apples 1kg", category: "Fresh Fruits", price: 180, stock: 60 },
  { name: "Tea 250g", category: "Beverages", price: 140, stock: 200 },
  { name: "Potato Chips 200g", category: "Snacks & Branded Foods", price: 60, stock: 200 }
]

products_data.each do |prod_data|
  category = Category.find_by(name: prod_data[:category])
  Product.find_or_create_by(name: prod_data[:name]) do |prod|
    prod.category_id = category&.id
    prod.price = prod_data[:price]
    prod.stock = prod_data[:stock]
    prod.status = "active"
    prod.description = "Sample #{prod_data[:name]}"
    prod.sku = "SKU-#{SecureRandom.hex(4).upcase}"
  end
end

puts "✅ Created #{Product.count} products"

# Create Customers if they don't exist
customers_data = [
  { first_name: "Rajesh", last_name: "Kumar", email: "rajesh.kumar@sample.com", mobile: "9876543210" },
  { first_name: "Priya", last_name: "Sharma", email: "priya.sharma@sample.com", mobile: "9876543211" },
  { first_name: "Amit", last_name: "Patel", email: "amit.patel@sample.com", mobile: "9876543212" },
  { first_name: "Sunita", last_name: "Singh", email: "sunita.singh@sample.com", mobile: "9876543213" },
  { first_name: "Vikram", last_name: "Reddy", email: "vikram.reddy@sample.com", mobile: "9876543214" }
]

customers_data.each do |cust_data|
  Customer.find_or_create_by(email: cust_data[:email]) do |cust|
    cust.assign_attributes(cust_data)
    cust.address = "Sample Address, Mumbai"
    cust.pincode = "400001"
    cust.created_at = Date.today - rand(0..30).days
  end
end

puts "✅ Created #{Customer.count} customers"

# Create sample bookings with items
10.times do |i|
  customer = Customer.all.sample
  product = Product.all.sample

  booking = Booking.create!(
    customer: customer,
    status: ["confirmed", "processing", "delivered", "completed"].sample,
    payment_method: "upi",
    payment_status: "paid",
    discount_amount: 0,
    customer_name: "#{customer.first_name} #{customer.last_name}",
    customer_email: customer.email,
    customer_phone: customer.mobile,
    delivery_address: customer.address,
    created_at: Date.today - rand(0..30).days
  )

  # Add a booking item
  booking.booking_items.create!(
    product: product,
    quantity: rand(1..3),
    price: product.price
  )
end

puts "✅ Created #{Booking.count} bookings with items"

# Create some orders from bookings
Order.destroy_all
Booking.all.each do |booking|
  if ["processing", "delivered", "completed"].include?(booking.status)
    order = Order.create!(
      booking: booking,
      customer: booking.customer,
      status: booking.status == "completed" ? "delivered" : booking.status,
      payment_method: booking.payment_method,
      payment_status: booking.payment_status,
      subtotal: booking.subtotal,
      tax_amount: booking.tax_amount,
      discount_amount: booking.discount_amount,
      total_amount: booking.total_amount,
      customer_name: booking.customer_name,
      customer_email: booking.customer_email,
      customer_phone: booking.customer_phone,
      delivery_address: booking.delivery_address,
      tracking_number: "TRK#{SecureRandom.hex(6).upcase}",
      created_at: booking.created_at
    )

    # Copy booking items to order items
    booking.booking_items.each do |booking_item|
      order.order_items.create!(
        product: booking_item.product,
        quantity: booking_item.quantity,
        price: booking_item.price
      )
    end
  end
end

puts "✅ Created #{Order.count} orders"

puts "🎉 Dashboard sample data created successfully!"
puts "\n📊 Summary:"
puts "- Categories: #{Category.count}"
puts "- Products: #{Product.count}"
puts "- Customers: #{Customer.count}"
puts "- Bookings: #{Booking.count}"
puts "- Orders: #{Order.count}"