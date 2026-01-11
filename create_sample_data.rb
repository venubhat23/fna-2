# Sample Data Creation Script for E-commerce Store
puts "🚀 Starting sample data creation..."

# Clear existing data (optional - uncomment if you want to start fresh)
# puts "Clearing existing data..."
# DeliveryPerson.destroy_all
# Product.destroy_all
# Category.destroy_all
# Customer.destroy_all

# Create Categories
puts "\n📂 Creating Categories..."

categories_data = [
  {
    name: "Electronics",
    description: "Latest electronic gadgets and devices",
    status: true,
    display_order: 1,
    subcategories: [
      { name: "Smartphones", description: "Latest smartphones and mobile devices" },
      { name: "Laptops", description: "High-performance laptops and notebooks" },
      { name: "Tablets", description: "Tablets and e-readers" },
      { name: "Accessories", description: "Phone cases, chargers, and electronic accessories" }
    ]
  },
  {
    name: "Fashion",
    description: "Trendy clothing and fashion accessories",
    status: true,
    display_order: 2,
    subcategories: [
      { name: "Men's Clothing", description: "Shirts, pants, jackets for men" },
      { name: "Women's Clothing", description: "Dresses, tops, pants for women" },
      { name: "Shoes", description: "Footwear for all occasions" },
      { name: "Bags", description: "Handbags, backpacks, and luggage" }
    ]
  },
  {
    name: "Home & Kitchen",
    description: "Home essentials and kitchen appliances",
    status: true,
    display_order: 3,
    subcategories: [
      { name: "Kitchen Appliances", description: "Blenders, microwaves, and cooking equipment" },
      { name: "Home Decor", description: "Decorative items and furnishings" },
      { name: "Furniture", description: "Chairs, tables, and storage solutions" },
      { name: "Cleaning Supplies", description: "Cleaning products and tools" }
    ]
  },
  {
    name: "Books & Media",
    description: "Books, movies, and educational content",
    status: true,
    display_order: 4,
    subcategories: [
      { name: "Fiction Books", description: "Novels, stories, and literature" },
      { name: "Non-Fiction", description: "Educational and informative books" },
      { name: "Movies & TV", description: "DVDs, Blu-rays, and digital media" }
    ]
  },
  {
    name: "Sports & Fitness",
    description: "Sports equipment and fitness gear",
    status: true,
    display_order: 5,
    subcategories: [
      { name: "Exercise Equipment", description: "Weights, yoga mats, and workout gear" },
      { name: "Outdoor Sports", description: "Cricket, football, and outdoor games" },
      { name: "Fitness Accessories", description: "Water bottles, towels, and supplements" }
    ]
  }
]

parent_categories = {}

categories_data.each do |cat_data|
  parent = Category.create!(
    name: cat_data[:name],
    description: cat_data[:description],
    status: cat_data[:status],
    display_order: cat_data[:display_order],
    parent_id: nil
  )
  parent_categories[cat_data[:name]] = parent
  puts "✅ Created parent category: #{parent.name}"

  cat_data[:subcategories].each_with_index do |subcat_data, index|
    subcategory = Category.create!(
      name: subcat_data[:name],
      description: subcat_data[:description],
      status: true,
      display_order: index + 1,
      parent_id: parent.id
    )
    puts "  └── Created subcategory: #{subcategory.name}"
  end
end

puts "📂 Created #{Category.count} categories total"

# Create Customers
puts "\n👥 Creating Customers..."

customers_data = [
  {
    first_name: "Rajesh",
    last_name: "Kumar",
    email: "rajesh.kumar@email.com",
    mobile: "9876543210",
    date_of_birth: Date.new(1985, 3, 15),
    gender: "Male",
    address: "123 MG Road",
    city: "Bangalore",
    state: "Karnataka",
    pincode: "560001",
    country: "India",
    status: true,
    password: "password123"
  },
  {
    first_name: "Priya",
    last_name: "Sharma",
    email: "priya.sharma@email.com",
    mobile: "9876543211",
    date_of_birth: Date.new(1990, 7, 22),
    gender: "Female",
    address: "456 Brigade Road",
    city: "Bangalore",
    state: "Karnataka",
    pincode: "560025",
    country: "India",
    status: true,
    password: "password123"
  },
  {
    first_name: "Amit",
    last_name: "Patel",
    email: "amit.patel@email.com",
    mobile: "9876543212",
    date_of_birth: Date.new(1988, 12, 5),
    gender: "Male",
    address: "789 Commercial Street",
    city: "Mumbai",
    state: "Maharashtra",
    pincode: "400001",
    country: "India",
    status: true,
    password: "password123"
  },
  {
    first_name: "Sneha",
    last_name: "Reddy",
    email: "sneha.reddy@email.com",
    mobile: "9876543213",
    date_of_birth: Date.new(1992, 4, 18),
    gender: "Female",
    address: "321 Park Street",
    city: "Hyderabad",
    state: "Telangana",
    pincode: "500001",
    country: "India",
    status: true,
    password: "password123"
  },
  {
    first_name: "Vikram",
    last_name: "Singh",
    email: "vikram.singh@email.com",
    mobile: "9876543214",
    date_of_birth: Date.new(1987, 9, 30),
    gender: "Male",
    address: "654 Connaught Place",
    city: "New Delhi",
    state: "Delhi",
    pincode: "110001",
    country: "India",
    status: true,
    password: "password123"
  },
  {
    first_name: "Anita",
    last_name: "Joshi",
    email: "anita.joshi@email.com",
    mobile: "9876543215",
    date_of_birth: Date.new(1991, 11, 12),
    gender: "Female",
    address: "987 FC Road",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411005",
    country: "India",
    status: true,
    password: "password123"
  },
  {
    first_name: "Rahul",
    last_name: "Agarwal",
    email: "rahul.agarwal@email.com",
    mobile: "9876543216",
    date_of_birth: Date.new(1989, 6, 8),
    gender: "Male",
    address: "147 Salt Lake City",
    city: "Kolkata",
    state: "West Bengal",
    pincode: "700064",
    country: "India",
    status: true,
    password: "password123"
  },
  {
    first_name: "Kavitha",
    last_name: "Nair",
    email: "kavitha.nair@email.com",
    mobile: "9876543217",
    date_of_birth: Date.new(1993, 1, 25),
    gender: "Female",
    address: "258 Marine Drive",
    city: "Chennai",
    state: "Tamil Nadu",
    pincode: "600001",
    country: "India",
    status: true,
    password: "password123"
  }
]

customers_data.each do |customer_data|
  customer = Customer.create!(customer_data)
  puts "✅ Created customer: #{customer.display_name} (#{customer.email})"
end

puts "👥 Created #{Customer.count} customers total"

# Create Products
puts "\n📦 Creating Products..."

products_data = [
  # Electronics - Smartphones
  {
    name: "iPhone 15 Pro",
    description: "Latest iPhone with advanced camera system and A17 Pro chip",
    category: "Smartphones",
    price: 129900,
    discount_price: 119900,
    stock: 25,
    status: "active",
    sku: "IPHONE15PRO128",
    weight: 0.187,
    dimensions: "146.6 x 70.6 x 8.25"
  },
  {
    name: "Samsung Galaxy S24",
    description: "Premium Android smartphone with excellent display and camera",
    category: "Smartphones",
    price: 89999,
    discount_price: 79999,
    stock: 30,
    status: "active",
    sku: "SAMS24ULTRA256",
    weight: 0.196,
    dimensions: "147.0 x 70.6 x 8.6"
  },
  {
    name: "OnePlus 12",
    description: "Flagship killer with Snapdragon 8 Gen 3 processor",
    category: "Smartphones",
    price: 64999,
    discount_price: 59999,
    stock: 20,
    status: "active",
    sku: "OP12256GB",
    weight: 0.220,
    dimensions: "164.3 x 75.8 x 9.2"
  },

  # Electronics - Laptops
  {
    name: "MacBook Air M3",
    description: "Ultra-thin laptop with M3 chip for exceptional performance",
    category: "Laptops",
    price: 134900,
    discount_price: 124900,
    stock: 15,
    status: "active",
    sku: "MBA15M3512",
    weight: 1.51,
    dimensions: "34.04 x 23.76 x 1.13"
  },
  {
    name: "Dell XPS 13",
    description: "Premium ultrabook with InfinityEdge display",
    category: "Laptops",
    price: 95999,
    discount_price: 89999,
    stock: 12,
    status: "active",
    sku: "DELLXPS13I7",
    weight: 1.27,
    dimensions: "29.57 x 19.86 x 1.58"
  },
  {
    name: "HP Pavilion 15",
    description: "Versatile laptop for work and entertainment",
    category: "Laptops",
    price: 65999,
    discount_price: 59999,
    stock: 18,
    status: "active",
    sku: "HPPAV15I516",
    weight: 1.75,
    dimensions: "35.85 x 24.2 x 1.79"
  },

  # Fashion - Men's Clothing
  {
    name: "Cotton Casual Shirt",
    description: "Comfortable cotton shirt perfect for casual wear",
    category: "Men's Clothing",
    price: 1999,
    discount_price: 1499,
    stock: 50,
    status: "active",
    sku: "COTSHIRTM001",
    weight: 0.3,
    dimensions: "Standard fit"
  },
  {
    name: "Denim Jeans",
    description: "Premium quality denim jeans with perfect fit",
    category: "Men's Clothing",
    price: 2999,
    discount_price: 2499,
    stock: 40,
    status: "active",
    sku: "DENIMJM002",
    weight: 0.6,
    dimensions: "Regular fit"
  },

  # Fashion - Women's Clothing
  {
    name: "Summer Dress",
    description: "Light and breezy summer dress in vibrant colors",
    category: "Women's Clothing",
    price: 2499,
    discount_price: 1999,
    stock: 35,
    status: "active",
    sku: "SUMDRESSW001",
    weight: 0.25,
    dimensions: "Free size"
  },
  {
    name: "Elegant Blouse",
    description: "Professional blouse suitable for office and formal occasions",
    category: "Women's Clothing",
    price: 1799,
    discount_price: 1299,
    stock: 45,
    status: "active",
    sku: "ELEGBLW002",
    weight: 0.2,
    dimensions: "Standard fit"
  },

  # Home & Kitchen
  {
    name: "Philips Air Fryer",
    description: "Healthy cooking with Rapid Air technology",
    category: "Kitchen Appliances",
    price: 12999,
    discount_price: 9999,
    stock: 10,
    status: "active",
    sku: "PHILAF3L",
    weight: 4.8,
    dimensions: "28.7 x 38.4 x 31.5"
  },
  {
    name: "Wooden Dining Table",
    description: "Solid wood dining table for 6 people",
    category: "Furniture",
    price: 25999,
    discount_price: 22999,
    stock: 5,
    status: "active",
    sku: "WOODTABLE6S",
    weight: 45.0,
    dimensions: "180 x 90 x 75"
  },

  # Books & Media
  {
    name: "The Alchemist",
    description: "Bestselling novel by Paulo Coelho",
    category: "Fiction Books",
    price: 399,
    discount_price: 299,
    stock: 100,
    status: "active",
    sku: "ALCHEMIST001",
    weight: 0.2,
    dimensions: "19.8 x 12.9 x 1.5"
  },

  # Sports & Fitness
  {
    name: "Yoga Mat Premium",
    description: "Non-slip yoga mat with excellent grip and cushioning",
    category: "Exercise Equipment",
    price: 1999,
    discount_price: 1499,
    stock: 25,
    status: "active",
    sku: "YOGAMATPREM",
    weight: 1.2,
    dimensions: "183 x 61 x 0.6"
  },
  {
    name: "Cricket Bat Professional",
    description: "High-quality cricket bat for professional players",
    category: "Outdoor Sports",
    price: 4999,
    discount_price: 3999,
    stock: 15,
    status: "active",
    sku: "CRICBATPRO",
    weight: 1.2,
    dimensions: "86.4 x 10.8 x 6.7"
  }
]

products_data.each do |product_data|
  category = Category.find_by(name: product_data[:category])
  if category
    product = Product.create!(
      name: product_data[:name],
      description: product_data[:description],
      category_id: category.id,
      price: product_data[:price],
      discount_price: product_data[:discount_price],
      stock: product_data[:stock],
      status: product_data[:status],
      sku: product_data[:sku],
      weight: product_data[:weight],
      dimensions: product_data[:dimensions]
    )
    puts "✅ Created product: #{product.name} (₹#{product.price})"
  else
    puts "❌ Category not found for: #{product_data[:name]}"
  end
end

puts "📦 Created #{Product.count} products total"

# Create Delivery People
puts "\n🚚 Creating Delivery People..."

delivery_people_data = [
  {
    first_name: "Ravi",
    last_name: "Kumar",
    email: "ravi.delivery@company.com",
    mobile: "9998887776",
    vehicle_type: "Motorcycle",
    vehicle_number: "KA01AB1234",
    license_number: "KA1234567890",
    address: "BTM Layout",
    city: "Bangalore",
    state: "Karnataka",
    pincode: "560076",
    emergency_contact_name: "Sunita Kumar",
    emergency_contact_mobile: "9998887777",
    joining_date: Date.current - 1.year,
    salary: 25000,
    status: true,
    delivery_areas: "BTM Layout, Koramangala, HSR Layout"
  },
  {
    first_name: "Mohammed",
    last_name: "Ali",
    email: "mohammed.delivery@company.com",
    mobile: "9998887778",
    vehicle_type: "Motorcycle",
    vehicle_number: "KA01CD5678",
    license_number: "KA1234567891",
    address: "Whitefield",
    city: "Bangalore",
    state: "Karnataka",
    pincode: "560066",
    emergency_contact_name: "Fatima Ali",
    emergency_contact_mobile: "9998887779",
    joining_date: Date.current - 8.months,
    salary: 23000,
    status: true,
    delivery_areas: "Whitefield, ITPL, Marathahalli"
  },
  {
    first_name: "Suresh",
    last_name: "Patil",
    email: "suresh.delivery@company.com",
    mobile: "9998887780",
    vehicle_type: "Scooter",
    vehicle_number: "MH12EF9012",
    license_number: "MH1234567892",
    address: "Andheri",
    city: "Mumbai",
    state: "Maharashtra",
    pincode: "400058",
    emergency_contact_name: "Meera Patil",
    emergency_contact_mobile: "9998887781",
    joining_date: Date.current - 6.months,
    salary: 24000,
    status: true,
    delivery_areas: "Andheri, Bandra, Juhu"
  },
  {
    first_name: "Deepak",
    last_name: "Yadav",
    email: "deepak.delivery@company.com",
    mobile: "9998887782",
    vehicle_type: "Motorcycle",
    vehicle_number: "DL05GH3456",
    license_number: "DL1234567893",
    address: "Lajpat Nagar",
    city: "New Delhi",
    state: "Delhi",
    pincode: "110024",
    emergency_contact_name: "Rekha Yadav",
    emergency_contact_mobile: "9998887783",
    joining_date: Date.current - 1.5.years,
    salary: 26000,
    status: true,
    delivery_areas: "Lajpat Nagar, CP, Khan Market"
  },
  {
    first_name: "Ganesh",
    last_name: "Chavan",
    email: "ganesh.delivery@company.com",
    mobile: "9998887784",
    vehicle_type: "Motorcycle",
    vehicle_number: "MH14IJ7890",
    license_number: "MH1234567894",
    address: "Kothrud",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411038",
    emergency_contact_name: "Lata Chavan",
    emergency_contact_mobile: "9998887785",
    joining_date: Date.current - 10.months,
    salary: 22000,
    status: true,
    delivery_areas: "Kothrud, Shivaji Nagar, FC Road"
  },
  {
    first_name: "Rajesh",
    last_name: "Das",
    email: "rajesh.delivery@company.com",
    mobile: "9998887786",
    vehicle_type: "Scooter",
    vehicle_number: "WB07KL1234",
    license_number: "WB1234567895",
    address: "Salt Lake",
    city: "Kolkata",
    state: "West Bengal",
    pincode: "700064",
    emergency_contact_name: "Mamata Das",
    emergency_contact_mobile: "9998887787",
    joining_date: Date.current - 4.months,
    salary: 21000,
    status: true,
    delivery_areas: "Salt Lake, New Town, Sector V"
  }
]

delivery_people_data.each do |delivery_data|
  delivery_person = DeliveryPerson.create!(delivery_data)
  puts "✅ Created delivery person: #{delivery_person.first_name} #{delivery_person.last_name} (#{delivery_person.city})"
end

puts "🚚 Created #{DeliveryPerson.count} delivery people total"

# Summary
puts "\n🎉 Sample data creation completed!"
puts "=" * 50
puts "📊 SUMMARY:"
puts "👥 Customers: #{Customer.count}"
puts "📂 Categories: #{Category.count} (#{Category.where(parent_id: nil).count} parent, #{Category.where.not(parent_id: nil).count} sub)"
puts "📦 Products: #{Product.count}"
puts "🚚 Delivery People: #{DeliveryPerson.count}"
puts "=" * 50
puts "\n🚀 You can now test your CRUD operations with this sample data!"
puts "🌐 Visit your admin panel to see the data in action."