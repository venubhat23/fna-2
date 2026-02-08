# Dashboard Sample Data Seeds
puts "Creating sample data for attractive dashboard..."

# Create Categories
categories = [
  { name: 'Electronics', description: 'Electronic gadgets and devices', status: true },
  { name: 'Clothing', description: 'Fashion and apparel', status: true },
  { name: 'Home & Garden', description: 'Home decor and garden supplies', status: true },
  { name: 'Books', description: 'Books and stationery', status: true },
  { name: 'Sports', description: 'Sports equipment and accessories', status: true },
  { name: 'Toys', description: 'Kids toys and games', status: true },
  { name: 'Beauty', description: 'Beauty and personal care', status: true },
  { name: 'Food & Beverages', description: 'Food items and drinks', status: true }
]

categories.each do |cat_data|
  Category.find_or_create_by(name: cat_data[:name]) do |cat|
    cat.description = cat_data[:description]
    cat.status = cat_data[:status]
  end
end
puts "✅ Created #{Category.count} categories"

# Create Products
electronics = Category.find_by(name: 'Electronics')
clothing = Category.find_by(name: 'Clothing')
home = Category.find_by(name: 'Home & Garden')
books = Category.find_by(name: 'Books')
sports = Category.find_by(name: 'Sports')

products_data = [
  # Electronics
  { name: 'iPhone 15 Pro', category: electronics, price: 125000, stock: 15, status: 'active', sku: 'IP15P' },
  { name: 'Samsung Galaxy S24', category: electronics, price: 95000, stock: 20, status: 'active', sku: 'SGS24' },
  { name: 'MacBook Air M2', category: electronics, price: 115000, stock: 8, status: 'active', sku: 'MBA-M2' },
  { name: 'Sony WH-1000XM5', category: electronics, price: 29990, stock: 25, status: 'active', sku: 'SNY-XM5' },
  { name: 'iPad Pro 12.9"', category: electronics, price: 85000, stock: 12, status: 'active', sku: 'IPAD-P12' },
  { name: 'Dell XPS 13', category: electronics, price: 95000, stock: 3, status: 'active', sku: 'DELL-XPS13' },
  { name: 'AirPods Pro', category: electronics, price: 24900, stock: 30, status: 'active', sku: 'APP-2' },

  # Clothing
  { name: 'Premium Cotton T-Shirt', category: clothing, price: 1299, stock: 100, status: 'active', sku: 'TS-001' },
  { name: 'Denim Jeans', category: clothing, price: 2999, stock: 75, status: 'active', sku: 'JNS-001' },
  { name: 'Formal Shirt', category: clothing, price: 2499, stock: 4, status: 'active', sku: 'FS-001' },
  { name: 'Sports Shoes', category: clothing, price: 4999, stock: 50, status: 'active', sku: 'SHS-001' },
  { name: 'Winter Jacket', category: clothing, price: 5999, stock: 25, status: 'active', sku: 'WJ-001' },

  # Home & Garden
  { name: 'Smart LED Bulb', category: home, price: 999, stock: 200, status: 'active', sku: 'SLB-001' },
  { name: 'Coffee Maker', category: home, price: 8999, stock: 15, status: 'active', sku: 'CM-001' },
  { name: 'Yoga Mat', category: home, price: 1499, stock: 2, status: 'active', sku: 'YM-001' },
  { name: 'Plant Pot Set', category: home, price: 2999, stock: 40, status: 'active', sku: 'PP-001' },

  # Books
  { name: 'Best Seller Novel', category: books, price: 599, stock: 0, status: 'active', sku: 'BK-001' },
  { name: 'Programming Guide', category: books, price: 899, stock: 35, status: 'active', sku: 'BK-002' },
  { name: 'Cook Book', category: books, price: 799, stock: 20, status: 'active', sku: 'BK-003' },

  # Sports
  { name: 'Tennis Racket', category: sports, price: 7999, stock: 10, status: 'active', sku: 'TR-001' },
  { name: 'Football', category: sports, price: 1999, stock: 45, status: 'active', sku: 'FB-001' },
  { name: 'Gym Equipment Set', category: sports, price: 15999, stock: 5, status: 'active', sku: 'GYM-001' },
]

products_data.each do |prod_data|
  Product.find_or_create_by(sku: prod_data[:sku]) do |prod|
    prod.name = prod_data[:name]
    prod.category = prod_data[:category]
    prod.price = prod_data[:price]
    prod.stock = prod_data[:stock]
    prod.status = prod_data[:status]
    prod.description = "High quality #{prod_data[:name]}"
  end
end
puts "✅ Created #{Product.count} products"

# Create Customers
customers_data = [
  { first_name: 'Rajesh', last_name: 'Kumar', email: 'rajesh@example.com', mobile: '9876543210', city: 'Bangalore', state: 'Karnataka' },
  { first_name: 'Priya', last_name: 'Sharma', email: 'priya@example.com', mobile: '9876543211', city: 'Mumbai', state: 'Maharashtra' },
  { first_name: 'Amit', last_name: 'Patel', email: 'amit@example.com', mobile: '9876543212', city: 'Chennai', state: 'Tamil Nadu' },
  { first_name: 'Sneha', last_name: 'Gupta', email: 'sneha@example.com', mobile: '9876543213', city: 'Delhi', state: 'Delhi' },
  { first_name: 'Vikram', last_name: 'Singh', email: 'vikram@example.com', mobile: '9876543214', city: 'Pune', state: 'Maharashtra' },
  { first_name: 'Anjali', last_name: 'Nair', email: 'anjali@example.com', mobile: '9876543215', city: 'Kochi', state: 'Kerala' },
  { first_name: 'Rohit', last_name: 'Verma', email: 'rohit@example.com', mobile: '9876543216', city: 'Hyderabad', state: 'Telangana' },
  { first_name: 'Pooja', last_name: 'Reddy', email: 'pooja@example.com', mobile: '9876543217', city: 'Mysore', state: 'Karnataka' },
  { first_name: 'Karthik', last_name: 'Iyer', email: 'karthik@example.com', mobile: '9876543218', city: 'Coimbatore', state: 'Tamil Nadu' },
  { first_name: 'Deepika', last_name: 'Joshi', email: 'deepika@example.com', mobile: '9876543219', city: 'Ahmedabad', state: 'Gujarat' },
]

customers_data.each do |cust_data|
  unless Customer.exists?(email: cust_data[:email])
    password = "password123"
    cust = Customer.create!(
      first_name: cust_data[:first_name],
      last_name: cust_data[:last_name],
      email: cust_data[:email],
      mobile: cust_data[:mobile],
      city: cust_data[:city],
      state: cust_data[:state],
      address: "#{rand(1..999)} Main Street, #{cust_data[:city]}",
      birth_date: Date.today - rand(25..55).years - rand(1..365).days,
      status: true,
      customer_type: 'individual',
      password: password,
      password_confirmation: password
    )
  end
end
puts "✅ Created #{Customer.count} customers"

# Create Bookings with different statuses
customers = Customer.all.to_a
products = Product.where('stock > 0').to_a
payment_methods = ['cash', 'card', 'upi', 'online']
booking_statuses = ['draft', 'completed', 'cancelled', 'processing', 'delivered']

30.times do |i|
  customer = customers.sample
  status = booking_statuses.sample
  booking_date = Date.today - rand(0..60).days

  booking = Booking.create(
    customer: customer,
    customer_name: "#{customer.first_name} #{customer.last_name}",
    customer_email: customer.email,
    customer_phone: customer.mobile,
    booking_number: "BK#{Time.now.to_i}#{i}",
    booking_date: booking_date,
    status: status,
    payment_method: payment_methods.sample,
    payment_status: status == 'completed' ? 'paid' : 'unpaid',
    subtotal: 0,
    tax_amount: 0,
    discount_amount: rand(0..500),
    total_amount: 0,
    delivery_address: customer.address,
    created_at: booking_date,
    updated_at: booking_date
  )

  # Add items to booking
  num_items = rand(1..5)
  total = 0

  num_items.times do
    product = products.sample
    quantity = rand(1..3)
    price = product.price
    subtotal = price * quantity
    total += subtotal

    BookingItem.create(
      booking: booking,
      product: product,
      quantity: quantity,
      price: price,
      total: subtotal
    )
  end

  tax = (total * 0.18).round(2) # 18% GST
  booking.update(
    subtotal: total,
    tax_amount: tax,
    total_amount: total + tax - booking.discount_amount
  )
end
puts "✅ Created #{Booking.count} bookings"

# Create some Orders
10.times do |i|
  booking = Booking.where(status: 'completed').sample
  next unless booking

  order = Order.create(
    booking: booking,
    customer: booking.customer,
    order_number: "ORD#{Time.now.to_i}#{i}",
    order_date: booking.booking_date + 1.day,
    status: ['pending', 'shipped', 'delivered', 'cancelled'].sample,
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
    created_at: booking.created_at + 1.day,
    updated_at: booking.updated_at + 1.day
  )

  if order.status == 'delivered'
    order.update(delivered_at: order.order_date + rand(2..5).days)
  end
end
puts "✅ Created #{Order.count} orders"

# Create Vendors
vendors_data = [
  { name: 'TechDistro Pvt Ltd', email: 'contact@techdistro.com', mobile: '9898989898', address: 'Tech Park, Bangalore', status: true },
  { name: 'Fashion Hub Wholesale', email: 'info@fashionhub.com', mobile: '9797979797', address: 'Textile Market, Mumbai', status: true },
  { name: 'Home Essentials Inc', email: 'sales@homeessentials.com', mobile: '9696969696', address: 'Industrial Area, Delhi', status: true },
  { name: 'Book World Publishers', email: 'orders@bookworld.com', mobile: '9595959595', address: 'Publishing House, Chennai', status: true },
  { name: 'Sports Pro Suppliers', email: 'contact@sportspro.com', mobile: '9494949494', address: 'Sports Complex, Pune', status: false }
]

vendors_data.each do |vendor_data|
  Vendor.find_or_create_by(email: vendor_data[:email]) do |vendor|
    vendor.name = vendor_data[:name]
    vendor.mobile = vendor_data[:mobile]
    vendor.address = vendor_data[:address]
    vendor.status = vendor_data[:status]
    vendor.contact_person = vendor_data[:name].split.first + ' Manager'
  end
end
puts "✅ Created #{Vendor.count} vendors"

# Create Vendor Purchases
vendors = Vendor.all.to_a
15.times do |i|
  vendor = vendors.sample
  purchase_date = Date.today - rand(0..30).days

  purchase = VendorPurchase.create(
    vendor: vendor,
    purchase_number: "PO#{Time.now.to_i}#{i}",
    purchase_date: purchase_date,
    status: ['pending', 'approved', 'received', 'cancelled'].sample,
    total_amount: rand(50000..500000),
    notes: "Purchase order for inventory",
    created_at: purchase_date,
    updated_at: purchase_date
  )
end
puts "✅ Created #{VendorPurchase.count} vendor purchases"

# Create Stores
stores_data = [
  { name: 'Main Store - Bangalore', address: 'MG Road, Bangalore', city: 'Bangalore', state: 'Karnataka', status: true },
  { name: 'Mumbai Branch', address: 'Bandra West, Mumbai', city: 'Mumbai', state: 'Maharashtra', status: true },
  { name: 'Delhi Outlet', address: 'Connaught Place, Delhi', city: 'Delhi', state: 'Delhi', status: true },
  { name: 'Chennai Store', address: 'T Nagar, Chennai', city: 'Chennai', state: 'Tamil Nadu', status: true },
  { name: 'Pune Branch', address: 'Koregaon Park, Pune', city: 'Pune', state: 'Maharashtra', status: false }
]

stores_data.each do |store_data|
  Store.find_or_create_by(name: store_data[:name]) do |store|
    store.address = store_data[:address]
    store.city = store_data[:city]
    store.state = store_data[:state]
    store.status = store_data[:status]
    store.phone = "080-#{rand(1000000..9999999)}"
    store.email = store_data[:name].downcase.gsub(/[^a-z]/, '') + '@store.com'
  end
end
puts "✅ Created #{Store.count} stores"

puts "\n🎉 Dashboard sample data created successfully!"
puts "Visit http://localhost:3000 to see your attractive dashboard with real data!"