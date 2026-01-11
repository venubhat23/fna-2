puts 'Creating dummy data for ecommerce store...'

# Create delivery persons
puts 'Creating dummy delivery persons...'

delivery_people_data = [
  {
    first_name: 'Rajesh', last_name: 'Kumar', email: 'rajesh.kumar@delivery.com',
    mobile: '9876543210', vehicle_type: 'bike', vehicle_number: 'KA01AB1234',
    license_number: 'DL12345678', address: '123 Main Street', city: 'Bangalore',
    state: 'Karnataka', pincode: '560001', salary: 25000, status: true,
    emergency_contact_name: 'Sunita Kumar', emergency_contact_mobile: '9876543211',
    joining_date: 6.months.ago, delivery_areas: 'Bangalore Central, Koramangala, BTM Layout'
  },
  {
    first_name: 'Arjun', last_name: 'Singh', email: 'arjun.singh@delivery.com',
    mobile: '9876543212', vehicle_type: 'scooter', vehicle_number: 'KA01CD5678',
    license_number: 'DL87654321', address: '456 Park Road', city: 'Bangalore',
    state: 'Karnataka', pincode: '560002', salary: 22000, status: true,
    emergency_contact_name: 'Priya Singh', emergency_contact_mobile: '9876543213',
    joining_date: 4.months.ago, delivery_areas: 'Whitefield, Electronic City, HSR Layout'
  },
  {
    first_name: 'Mohammed', last_name: 'Ali', email: 'mohammed.ali@delivery.com',
    mobile: '9876543214', vehicle_type: 'bike', vehicle_number: 'KA01EF9012',
    license_number: 'DL11223344', address: '789 Commercial Street', city: 'Bangalore',
    state: 'Karnataka', pincode: '560003', salary: 28000, status: true,
    emergency_contact_name: 'Fatima Ali', emergency_contact_mobile: '9876543215',
    joining_date: 8.months.ago, delivery_areas: 'MG Road, Brigade Road, Jayanagar'
  },
  {
    first_name: 'Suresh', last_name: 'Reddy', email: 'suresh.reddy@delivery.com',
    mobile: '9876543216', vehicle_type: 'car', vehicle_number: 'KA01GH3456',
    license_number: 'DL55667788', address: '321 Ring Road', city: 'Bangalore',
    state: 'Karnataka', pincode: '560004', salary: 24000, status: false,
    emergency_contact_name: 'Lakshmi Reddy', emergency_contact_mobile: '9876543217',
    joining_date: 2.months.ago, delivery_areas: 'Marathahalli, Sarjapur, Bellandur'
  },
  {
    first_name: 'Vikram', last_name: 'Patel', email: 'vikram.patel@delivery.com',
    mobile: '9876543218', vehicle_type: 'scooter', vehicle_number: 'KA01IJ7890',
    license_number: 'DL99887766', address: '654 Tech Park', city: 'Bangalore',
    state: 'Karnataka', pincode: '560005', salary: 26000, status: true,
    emergency_contact_name: 'Meera Patel', emergency_contact_mobile: '9876543219',
    joining_date: 1.year.ago, delivery_areas: 'Indiranagar, Domlur, Airport Road'
  },
  {
    first_name: 'Ravi', last_name: 'Kumar', email: 'ravi.kumar@delivery.com',
    mobile: '9876543220', vehicle_type: 'van', vehicle_number: 'KA01KL1111',
    license_number: 'DL44556677', address: '987 Industrial Area', city: 'Bangalore',
    state: 'Karnataka', pincode: '560006', salary: 30000, status: true,
    emergency_contact_name: 'Meena Kumar', emergency_contact_mobile: '9876543221',
    joining_date: 18.months.ago, delivery_areas: 'All Bangalore Areas'
  },
  {
    first_name: 'Deepak', last_name: 'Rao', email: 'deepak.rao@delivery.com',
    mobile: '9876543222', vehicle_type: 'truck', vehicle_number: 'KA01MN2222',
    license_number: 'DL22334455', address: '456 Transport Nagar', city: 'Bangalore',
    state: 'Karnataka', pincode: '560007', salary: 35000, status: true,
    emergency_contact_name: 'Suma Rao', emergency_contact_mobile: '9876543223',
    joining_date: 2.years.ago, delivery_areas: 'Bangalore, Mysore, Mandya'
  }
]

delivery_people_data.each do |person_data|
  if defined?(DeliveryPerson) && DeliveryPerson.where(email: person_data[:email]).exists?
    puts "Delivery person #{person_data[:first_name]} #{person_data[:last_name]} already exists"
  elsif defined?(DeliveryPerson)
    person = DeliveryPerson.create!(person_data)
    puts "✅ Created delivery person: #{person.first_name} #{person.last_name} (#{person.vehicle_type})"
  else
    puts "❌ DeliveryPerson model not found"
  end
end

puts "\n📦 Delivery persons created: #{defined?(DeliveryPerson) ? DeliveryPerson.count : 0}"

# Create coupons
puts "\nCreating dummy coupons..."

coupon_data = [
  {
    code: 'WELCOME10', description: 'Welcome discount for new customers',
    discount_type: 'percentage', discount_value: 10.0, minimum_amount: 500.0,
    maximum_discount: 100.0, usage_limit: 100, used_count: 15,
    valid_from: 1.month.ago, valid_until: 1.month.from_now, status: true
  },
  {
    code: 'SAVE20', description: '20% off on orders above ₹1000',
    discount_type: 'percentage', discount_value: 20.0, minimum_amount: 1000.0,
    maximum_discount: 200.0, usage_limit: 50, used_count: 8,
    valid_from: 2.weeks.ago, valid_until: 2.weeks.from_now, status: true
  },
  {
    code: 'FLAT100', description: 'Flat ₹100 off on any order',
    discount_type: 'fixed', discount_value: 100.0, minimum_amount: 800.0,
    maximum_discount: 100.0, usage_limit: 200, used_count: 45,
    valid_from: 1.week.ago, valid_until: 3.weeks.from_now, status: true
  },
  {
    code: 'MEGA50', description: 'Mega sale - 50% off (limited time)',
    discount_type: 'percentage', discount_value: 50.0, minimum_amount: 2000.0,
    maximum_discount: 500.0, usage_limit: 25, used_count: 22,
    valid_from: 3.days.ago, valid_until: 4.days.from_now, status: true
  },
  {
    code: 'EXPIRED20', description: 'Expired 20% discount',
    discount_type: 'percentage', discount_value: 20.0, minimum_amount: 500.0,
    maximum_discount: 150.0, usage_limit: 75, used_count: 30,
    valid_from: 2.months.ago, valid_until: 1.week.ago, status: false
  },
  {
    code: 'FUTURE25', description: 'Future 25% discount (not yet active)',
    discount_type: 'percentage', discount_value: 25.0, minimum_amount: 1500.0,
    maximum_discount: 300.0, usage_limit: 40, used_count: 0,
    valid_from: 1.week.from_now, valid_until: 1.month.from_now, status: true
  }
]

coupon_data.each do |coupon_info|
  if defined?(Coupon) && Coupon.where(code: coupon_info[:code]).exists?
    puts "Coupon #{coupon_info[:code]} already exists"
  elsif defined?(Coupon)
    coupon = Coupon.create!(coupon_info)
    puts "✅ Created coupon: #{coupon.code} (#{coupon.discount_value}#{coupon.discount_type == 'percentage' ? '%' : '₹'} off)"
  else
    puts "❌ Coupon model not found"
  end
end

puts "\n🎫 Coupons created: #{defined?(Coupon) ? Coupon.count : 0}"

# Create sample categories if they don't exist
puts "\nCreating sample categories..."

categories_data = [
  { name: 'Electronics', description: 'Electronic devices and gadgets', status: true, display_order: 1 },
  { name: 'Clothing', description: 'Men and women apparel', status: true, display_order: 2 },
  { name: 'Books', description: 'Books and educational materials', status: true, display_order: 3 },
  { name: 'Home & Garden', description: 'Home improvement and garden supplies', status: true, display_order: 4 }
]

categories_data.each do |cat_data|
  if defined?(Category) && Category.where(name: cat_data[:name]).exists?
    puts "Category #{cat_data[:name]} already exists"
  elsif defined?(Category)
    category = Category.create!(cat_data)
    puts "✅ Created category: #{category.name}"
  else
    puts "❌ Category model not found"
  end
end

# Create sample products
puts "\nCreating sample products..."

if defined?(Category) && defined?(Product)
  electronics = Category.find_by(name: 'Electronics')
  clothing = Category.find_by(name: 'Clothing')
  books = Category.find_by(name: 'Books')

  products_data = [
    {
      name: 'iPhone 14 Pro', description: 'Latest iPhone with advanced features',
      category: electronics, price: 120000.0, discount_price: 115000.0,
      stock: 25, status: 'active', sku: 'IPH14PRO001', weight: 0.2
    },
    {
      name: 'Samsung Galaxy S23', description: 'Premium Android smartphone',
      category: electronics, price: 80000.0, discount_price: 75000.0,
      stock: 18, status: 'active', sku: 'SAM23001', weight: 0.19
    },
    {
      name: 'Cotton T-Shirt', description: 'Premium quality cotton t-shirt',
      category: clothing, price: 1200.0, discount_price: 999.0,
      stock: 50, status: 'active', sku: 'CTSH001', weight: 0.15
    },
    {
      name: 'Denim Jeans', description: 'Classic blue denim jeans',
      category: clothing, price: 2500.0, discount_price: 2200.0,
      stock: 30, status: 'active', sku: 'JEANS001', weight: 0.6
    },
    {
      name: 'Programming Book', description: 'Learn programming fundamentals',
      category: books, price: 800.0, stock: 15, status: 'active', sku: 'BOOK001', weight: 0.4
    },
    {
      name: 'Out of Stock Item', description: 'This item is out of stock',
      category: electronics, price: 5000.0, stock: 0, status: 'active', sku: 'OOS001', weight: 0.3
    }
  ]

  products_data.each do |prod_data|
    if Product.where(sku: prod_data[:sku]).exists?
      puts "Product #{prod_data[:name]} already exists"
    else
      product = Product.create!(prod_data)
      puts "✅ Created product: #{product.name} (₹#{product.price})"
    end
  end

  puts "\n📱 Products created: #{Product.count}"
else
  puts "❌ Category or Product model not found"
end

# Create sample customers if they don't exist
puts "\nCreating sample customers..."

if defined?(Customer)
  customers_data = [
    {
      first_name: 'Amit', last_name: 'Sharma', email: 'amit.sharma@example.com',
      mobile: '9876543201', customer_type: 'individual', status: true,
      address: '123 MG Road, Bangalore', city: 'Bangalore', state: 'Karnataka'
    },
    {
      first_name: 'Priya', last_name: 'Patel', email: 'priya.patel@example.com',
      mobile: '9876543202', customer_type: 'individual', status: true,
      address: '456 Brigade Road, Bangalore', city: 'Bangalore', state: 'Karnataka'
    },
    {
      first_name: 'Corporate', last_name: 'Solutions', email: 'corporate@solutions.com',
      mobile: '9876543203', customer_type: 'corporate', status: true,
      address: '789 Tech Park, Whitefield', city: 'Bangalore', state: 'Karnataka'
    }
  ]

  customers_data.each do |cust_data|
    if Customer.where(email: cust_data[:email]).exists?
      puts "Customer #{cust_data[:email]} already exists"
    else
      customer = Customer.create!(cust_data)
      puts "✅ Created customer: #{customer.display_name}"
    end
  end

  puts "\n👥 Customers created: #{Customer.count}"
else
  puts "❌ Customer model not found"
end

puts "\n🎉 Dummy data creation completed!"
puts "📊 Summary:"
puts "   Delivery Persons: #{defined?(DeliveryPerson) ? DeliveryPerson.count : 'N/A'}"
puts "   Coupons: #{defined?(Coupon) ? Coupon.count : 'N/A'}"
puts "   Categories: #{defined?(Category) ? Category.count : 'N/A'}"
puts "   Products: #{defined?(Product) ? Product.count : 'N/A'}"
puts "   Customers: #{defined?(Customer) ? Customer.count : 'N/A'}"