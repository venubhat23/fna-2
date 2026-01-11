# Dashboard Sample Data Generation Script
# This script creates realistic sample data for all dashboard visualizations

puts "🌱 Seeding dashboard data..."

# Clear existing data (optional - comment out if you want to keep existing data)
# Order.destroy_all
# Booking.destroy_all
# Product.destroy_all
# Category.destroy_all
# Customer.destroy_all

# Create Categories with realistic names
categories = [
  { name: "Grocery & Pantry", description: "Essential grocery items", status: true, display_order: 1 },
  { name: "Fresh Vegetables", description: "Farm fresh vegetables", status: true, display_order: 2 },
  { name: "Dairy & Milk Products", description: "Dairy and milk products", status: true, display_order: 3 },
  { name: "Fresh Fruits", description: "Seasonal fresh fruits", status: true, display_order: 4 },
  { name: "Beverages", description: "Hot and cold beverages", status: true, display_order: 5 },
  { name: "Snacks & Branded Foods", description: "Packaged snacks and foods", status: true, display_order: 6 },
  { name: "Personal Care", description: "Personal hygiene products", status: true, display_order: 7 },
  { name: "Home Care", description: "Cleaning and home care", status: true, display_order: 8 },
  { name: "Baby Care", description: "Baby products and care", status: true, display_order: 9 },
  { name: "Pet Supplies", description: "Pet food and supplies", status: true, display_order: 10 }
]

created_categories = categories.map do |cat_attrs|
  Category.find_or_create_by(name: cat_attrs[:name]) do |cat|
    cat.assign_attributes(cat_attrs)
  end
end

puts "✅ Created #{created_categories.count} categories"

# Create Products with varied prices and stock levels
products_data = [
  # Grocery & Pantry
  { name: "Basmati Rice 5kg", category: "Grocery & Pantry", price: 450, stock: 150, status: "active" },
  { name: "Wheat Flour 10kg", category: "Grocery & Pantry", price: 380, stock: 200, status: "active" },
  { name: "Toor Dal 1kg", category: "Grocery & Pantry", price: 145, stock: 180, status: "active" },
  { name: "Sugar 2kg", category: "Grocery & Pantry", price: 96, stock: 250, status: "active" },
  { name: "Cooking Oil 5L", category: "Grocery & Pantry", price: 750, stock: 120, status: "active" },

  # Fresh Vegetables
  { name: "Tomatoes 1kg", category: "Fresh Vegetables", price: 35, stock: 80, status: "active" },
  { name: "Onions 2kg", category: "Fresh Vegetables", price: 60, stock: 100, status: "active" },
  { name: "Potatoes 2kg", category: "Fresh Vegetables", price: 45, stock: 150, status: "active" },
  { name: "Carrots 500g", category: "Fresh Vegetables", price: 25, stock: 60, status: "active" },
  { name: "Green Beans 500g", category: "Fresh Vegetables", price: 40, stock: 45, status: "active" },

  # Dairy & Milk Products
  { name: "Full Cream Milk 1L", category: "Dairy & Milk Products", price: 68, stock: 50, status: "active" },
  { name: "Yogurt 400g", category: "Dairy & Milk Products", price: 45, stock: 40, status: "active" },
  { name: "Butter 500g", category: "Dairy & Milk Products", price: 280, stock: 30, status: "active" },
  { name: "Cheese Slices", category: "Dairy & Milk Products", price: 125, stock: 25, status: "active" },

  # Fresh Fruits
  { name: "Apples 1kg", category: "Fresh Fruits", price: 180, stock: 60, status: "active" },
  { name: "Bananas 12pc", category: "Fresh Fruits", price: 48, stock: 100, status: "active" },
  { name: "Oranges 1kg", category: "Fresh Fruits", price: 80, stock: 70, status: "active" },
  { name: "Grapes 500g", category: "Fresh Fruits", price: 90, stock: 40, status: "active" },

  # Beverages
  { name: "Tea 250g", category: "Beverages", price: 140, stock: 200, status: "active" },
  { name: "Coffee 200g", category: "Beverages", price: 380, stock: 100, status: "active" },
  { name: "Fruit Juice 1L", category: "Beverages", price: 110, stock: 80, status: "active" },
  { name: "Soft Drink 2L", category: "Beverages", price: 95, stock: 150, status: "active" },

  # Snacks
  { name: "Potato Chips 200g", category: "Snacks & Branded Foods", price: 60, stock: 200, status: "active" },
  { name: "Cookies 300g", category: "Snacks & Branded Foods", price: 85, stock: 150, status: "active" },
  { name: "Instant Noodles Pack", category: "Snacks & Branded Foods", price: 140, stock: 300, status: "active" },

  # Personal Care
  { name: "Shampoo 650ml", category: "Personal Care", price: 320, stock: 80, status: "active" },
  { name: "Soap Pack (4pc)", category: "Personal Care", price: 160, stock: 120, status: "active" },
  { name: "Toothpaste 200g", category: "Personal Care", price: 95, stock: 150, status: "active" },

  # Home Care
  { name: "Detergent 2kg", category: "Home Care", price: 280, stock: 100, status: "active" },
  { name: "Floor Cleaner 1L", category: "Home Care", price: 145, stock: 80, status: "active" },
  { name: "Dishwash Liquid 500ml", category: "Home Care", price: 110, stock: 90, status: "active" }
]

created_products = products_data.map do |prod_data|
  category = Category.find_by(name: prod_data[:category])
  Product.find_or_create_by(name: prod_data[:name]) do |prod|
    prod.category_id = category&.id
    prod.price = prod_data[:price]
    prod.stock = prod_data[:stock]
    prod.status = prod_data[:status]
    prod.description = "High quality #{prod_data[:name]}"
    prod.sku = "SKU-#{SecureRandom.hex(4).upcase}"
    prod.discount_price = prod_data[:price] * 0.9 # 10% discount
  end
end

puts "✅ Created #{created_products.count} products"

# Create Customers with diverse locations
customers_data = [
  { first_name: "Rajesh", last_name: "Kumar", email: "rajesh.kumar@example.com", mobile: "9876543210", city: "Mumbai", state: "Maharashtra" },
  { first_name: "Priya", last_name: "Sharma", email: "priya.sharma@example.com", mobile: "9876543211", city: "Delhi", state: "Delhi" },
  { first_name: "Amit", last_name: "Patel", email: "amit.patel@example.com", mobile: "9876543212", city: "Ahmedabad", state: "Gujarat" },
  { first_name: "Sunita", last_name: "Singh", email: "sunita.singh@example.com", mobile: "9876543213", city: "Bangalore", state: "Karnataka" },
  { first_name: "Vikram", last_name: "Reddy", email: "vikram.reddy@example.com", mobile: "9876543214", city: "Hyderabad", state: "Telangana" },
  { first_name: "Anjali", last_name: "Nair", email: "anjali.nair@example.com", mobile: "9876543215", city: "Kochi", state: "Kerala" },
  { first_name: "Rohit", last_name: "Verma", email: "rohit.verma@example.com", mobile: "9876543216", city: "Pune", state: "Maharashtra" },
  { first_name: "Neha", last_name: "Gupta", email: "neha.gupta@example.com", mobile: "9876543217", city: "Jaipur", state: "Rajasthan" },
  { first_name: "Karthik", last_name: "Iyer", email: "karthik.iyer@example.com", mobile: "9876543218", city: "Chennai", state: "Tamil Nadu" },
  { first_name: "Pooja", last_name: "Mehta", email: "pooja.mehta@example.com", mobile: "9876543219", city: "Surat", state: "Gujarat" }
]

created_customers = customers_data.map do |cust_data|
  Customer.find_or_create_by(email: cust_data[:email]) do |cust|
    cust.assign_attributes(cust_data)
    cust.address = "#{rand(1..999)}, Sample Street, #{cust_data[:city]}"
    cust.pincode = "#{rand(100000..999999)}"
    cust.birth_date = Date.today - rand(25..60).years
    cust.created_at = Date.today - rand(0..90).days
  end
end

puts "✅ Created #{created_customers.count} customers"

# Create Bookings and Orders with varied statuses
booking_statuses = ["draft", "confirmed", "processing", "delivered", "completed", "cancelled"]
payment_methods = ["cash", "card", "upi", "bank_transfer", "online"]
payment_statuses = ["unpaid", "paid", "partially_paid"]

# Generate bookings for the last 90 days
90.times do |i|
  date = Date.today - i.days

  # Create 0-5 bookings per day (more recent days have more bookings)
  num_bookings = i < 30 ? rand(2..5) : rand(0..3)

  num_bookings.times do
    customer = created_customers.sample
    status = booking_statuses.sample

    # Create booking items
    num_items = rand(1..5)
    booking_items = []
    subtotal = 0

    num_items.times do
      product = created_products.sample
      quantity = rand(1..3)
      item_price = product.discount_price || product.price
      item_total = item_price * quantity

      booking_items << {
        product_id: product.id,
        product_name: product.name,
        quantity: quantity,
        price: item_price,
        total: item_total
      }

      subtotal += item_total
    end

    tax_amount = (subtotal * 0.18).round(2) # 18% GST
    discount_amount = [0, 50, 100, [subtotal * 0.1, 150].min].sample.round(2)
    total_amount = [subtotal + tax_amount - discount_amount, 1].max

    booking = Booking.new(
      customer_id: customer.id,
      booking_number: "BK#{date.strftime('%Y%m%d')}#{SecureRandom.hex(3).upcase}",
      booking_date: date + rand(0..23).hours,
      status: status,
      payment_method: payment_methods.sample,
      payment_status: payment_statuses.sample,
      discount_amount: discount_amount,
      customer_name: "#{customer.first_name} #{customer.last_name}",
      customer_email: customer.email,
      customer_phone: customer.mobile,
      delivery_address: customer.address,
      notes: ["Urgent delivery", "Call before delivery", "Leave at door", nil].sample,
      created_at: date,
      updated_at: date
    )

    # Create booking items first
    booking_items.each do |item_data|
      booking.booking_items.build(
        product_id: item_data[:product_id],
        quantity: item_data[:quantity],
        price: item_data[:price]
      )
    end

    # Save booking (this will trigger calculate_totals)
    booking.save!

    # Create corresponding order for some bookings
    if ["processing", "delivered", "completed"].include?(status)
      order_status = case status
                    when "completed" then "delivered"
                    when "delivered" then "delivered"
                    else status
                    end

      order = Order.create!(
        booking_id: booking.id,
        customer_id: customer.id,
        order_number: "ORD#{date.strftime('%Y%m%d')}#{SecureRandom.hex(3).upcase}",
        order_date: booking.booking_date,
        status: order_status,
        payment_method: booking.payment_method,
        payment_status: booking.payment_status,
        subtotal: booking.subtotal,
        tax_amount: booking.tax_amount,
        discount_amount: booking.discount_amount,
        shipping_amount: [0, 40, 60, 80].sample,
        total_amount: booking.total_amount,
        customer_name: booking.customer_name,
        customer_email: booking.customer_email,
        customer_phone: booking.customer_phone,
        delivery_address: booking.delivery_address,
        tracking_number: "TRK#{SecureRandom.hex(6).upcase}",
        delivered_at: status == "delivered" ? date + rand(1..3).days : nil,
        created_at: date,
        updated_at: date
      )

      # Create order items from booking items
      booking.booking_items.each do |booking_item|
        order.order_items.create!(
          product_id: booking_item.product_id,
          quantity: booking_item.quantity,
          price: booking_item.price
        )
      end
    end
  end
end

puts "✅ Created #{Booking.count} bookings and #{Order.count} orders"

# Update product stock levels to simulate inventory changes
created_products.each do |product|
  # Simulate some products with low stock
  if rand < 0.2 # 20% chance of low stock
    product.update(stock: rand(1..10))
  elsif rand < 0.1 # 10% chance of out of stock
    product.update(stock: 0)
  end

  # Update price tracking fields
  product.update(
    yesterday_price: product.price * (1 + rand(-0.1..0.1)),
    today_price: product.price,
    price_change_percentage: rand(-10.0..10.0).round(2),
    last_price_update: DateTime.now
  )
end

puts "✅ Updated product inventory and pricing data"

# Create some product reviews
created_products.sample(15).each do |product|
  rand(1..5).times do
    customer = created_customers.sample
    ProductReview.create!(
      product_id: product.id,
      customer_id: customer.id,
      rating: rand(3..5),
      comment: ["Great product!", "Good value for money", "Excellent quality", "Fast delivery", "Highly recommended", "Worth the price"].sample,
      reviewer_name: "#{customer.first_name} #{customer.last_name}",
      reviewer_email: customer.email,
      status: 1, # approved
      verified_purchase: [true, false].sample,
      helpful_count: rand(0..20),
      created_at: Date.today - rand(0..30).days
    )
  end
end

puts "✅ Created #{ProductReview.count} product reviews"

# Create some coupons
coupons_data = [
  { code: "WELCOME10", description: "10% off for new customers", discount_type: "percentage", discount_value: 10, minimum_amount: 500, status: true },
  { code: "FLAT100", description: "Flat ₹100 off", discount_type: "fixed", discount_value: 100, minimum_amount: 1000, status: true },
  { code: "SUMMER20", description: "Summer sale 20% off", discount_type: "percentage", discount_value: 20, minimum_amount: 1500, status: true },
  { code: "FREE50", description: "₹50 off on orders above ₹500", discount_type: "fixed", discount_value: 50, minimum_amount: 500, status: true }
]

coupons_data.each do |coupon_data|
  Coupon.find_or_create_by(code: coupon_data[:code]) do |coupon|
    coupon.assign_attributes(coupon_data)
    coupon.valid_from = Date.today - 30.days
    coupon.valid_until = Date.today + 30.days
    coupon.usage_limit = 100
    coupon.used_count = rand(0..50)
  end
end

puts "✅ Created #{Coupon.count} coupons"

puts "🎉 Dashboard data seeding completed successfully!"
puts "\n📊 Summary:"
puts "- Categories: #{Category.count}"
puts "- Products: #{Product.count}"
puts "- Customers: #{Customer.count}"
puts "- Bookings: #{Booking.count}"
puts "- Orders: #{Order.count}"
puts "- Reviews: #{ProductReview.count}"
puts "- Coupons: #{Coupon.count}"