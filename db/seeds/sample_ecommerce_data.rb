# Sample Ecommerce Data Seeder
puts "Creating sample categories and products..."

# Create main categories
electronics = Category.find_or_create_by!(name: 'Electronics') do |c|
  c.description = 'Latest electronic gadgets and devices'
  c.status = true
  c.display_order = 1
end

fashion = Category.find_or_create_by!(name: 'Fashion') do |c|
  c.description = 'Trending fashion and clothing'
  c.status = true
  c.display_order = 2
end

home_garden = Category.find_or_create_by!(name: 'Home & Garden') do |c|
  c.description = 'Everything for your home and garden'
  c.status = true
  c.display_order = 3
end

sports = Category.find_or_create_by!(name: 'Sports & Fitness') do |c|
  c.description = 'Sports equipment and fitness gear'
  c.status = true
  c.display_order = 4
end

books = Category.find_or_create_by!(name: 'Books & Stationery') do |c|
  c.description = 'Books, notebooks and office supplies'
  c.status = true
  c.display_order = 5
end

# Create subcategories
smartphones = Category.find_or_create_by!(name: 'Smartphones', parent_id: electronics.id) do |c|
  c.description = 'Latest smartphones and accessories'
  c.status = true
  c.display_order = 1
end

laptops = Category.find_or_create_by!(name: 'Laptops', parent_id: electronics.id) do |c|
  c.description = 'Laptops and computing devices'
  c.status = true
  c.display_order = 2
end

mens_fashion = Category.find_or_create_by!(name: "Men's Fashion", parent_id: fashion.id) do |c|
  c.description = 'Fashion for men'
  c.status = true
  c.display_order = 1
end

womens_fashion = Category.find_or_create_by!(name: "Women's Fashion", parent_id: fashion.id) do |c|
  c.description = 'Fashion for women'
  c.status = true
  c.display_order = 2
end

puts "Created #{Category.count} categories"

# Create Products with placeholder images from Unsplash
products_data = [
  # Electronics - Smartphones
  {
    name: 'iPhone 15 Pro Max',
    description: 'The latest iPhone with A17 Pro chip, titanium design, and advanced camera system. Features 6.7" Super Retina XDR display, ProMotion technology, and all-day battery life.',
    category: smartphones,
    price: 134900,
    discount_price: 129900,
    stock: 50,
    sku: 'IPH15PM256',
    weight: 0.221,
    dimensions: '159.9 x 76.7 x 8.25 mm',
    image_url: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&q=80'
  },
  {
    name: 'Samsung Galaxy S24 Ultra',
    description: 'Premium Android flagship with S Pen, 200MP camera, and Galaxy AI. Features 6.8" Dynamic AMOLED display with 120Hz refresh rate.',
    category: smartphones,
    price: 129999,
    discount_price: 124999,
    stock: 35,
    sku: 'SGS24U256',
    weight: 0.233,
    dimensions: '162.3 x 79 x 8.6 mm',
    image_url: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800&q=80'
  },

  # Electronics - Laptops
  {
    name: 'MacBook Pro 16" M3 Max',
    description: 'Professional laptop with M3 Max chip, 36GB RAM, 1TB SSD. Features stunning Liquid Retina XDR display and up to 22 hours battery life.',
    category: laptops,
    price: 349900,
    discount_price: 339900,
    stock: 20,
    sku: 'MBP16M3M',
    weight: 2.16,
    dimensions: '35.57 x 24.81 x 1.68 cm',
    image_url: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80'
  },
  {
    name: 'Dell XPS 15 (2024)',
    description: 'Premium Windows laptop with Intel Core i9, 32GB RAM, NVIDIA RTX 4070. Features 15.6" OLED display with 3.5K resolution.',
    category: laptops,
    price: 239999,
    discount_price: 229999,
    stock: 15,
    sku: 'DXPS15-24',
    weight: 1.96,
    dimensions: '34.5 x 23.0 x 1.8 cm',
    image_url: 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&q=80'
  },

  # Fashion - Men's
  {
    name: 'Premium Cotton Formal Shirt',
    description: 'Elegant formal shirt made from 100% premium cotton. Slim fit design with spread collar and button cuffs. Perfect for office and formal occasions.',
    category: mens_fashion,
    price: 2499,
    discount_price: 1999,
    stock: 100,
    sku: 'MCFS-BLU-L',
    weight: 0.3,
    dimensions: 'Large (40)',
    image_url: 'https://images.unsplash.com/photo-1602810316498-ab67cf68c8e1?w=800&q=80'
  },
  {
    name: 'Leather Jacket - Classic Brown',
    description: 'Genuine leather jacket with vintage brown finish. Features zippered pockets, quilted lining, and adjustable waist tabs.',
    category: mens_fashion,
    price: 12999,
    discount_price: 10999,
    stock: 25,
    sku: 'MLJ-BRN-XL',
    weight: 1.2,
    dimensions: 'XL (42)',
    image_url: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800&q=80'
  },

  # Fashion - Women's
  {
    name: 'Elegant Evening Dress',
    description: 'Stunning evening dress in deep burgundy. Features elegant draping, flattering silhouette, and premium fabric blend.',
    category: womens_fashion,
    price: 5999,
    discount_price: 4999,
    stock: 40,
    sku: 'WED-BUR-M',
    weight: 0.5,
    dimensions: 'Medium',
    image_url: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&q=80'
  },
  {
    name: 'Designer Handbag Collection',
    description: 'Premium leather handbag with gold-tone hardware. Features multiple compartments, detachable strap, and signature brand detailing.',
    category: womens_fashion,
    price: 8999,
    discount_price: 7499,
    stock: 30,
    sku: 'WHB-LUX-01',
    weight: 0.8,
    dimensions: '30 x 25 x 12 cm',
    image_url: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80'
  },

  # Home & Garden
  {
    name: 'Smart Air Purifier Pro',
    description: 'Advanced air purifier with HEPA filter, smart sensors, and app control. Covers up to 500 sq ft, removes 99.97% of airborne particles.',
    category: home_garden,
    price: 24999,
    discount_price: 21999,
    stock: 45,
    sku: 'HAP-PRO-01',
    weight: 7.5,
    dimensions: '36 x 24 x 61 cm',
    image_url: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80'
  },
  {
    name: 'Ergonomic Office Chair',
    description: 'Premium ergonomic office chair with lumbar support, adjustable armrests, and breathable mesh back. Perfect for long work hours.',
    category: home_garden,
    price: 15999,
    discount_price: 13999,
    stock: 20,
    sku: 'HOC-ERG-01',
    weight: 18,
    dimensions: '68 x 68 x 120 cm',
    image_url: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800&q=80'
  },

  # Sports & Fitness
  {
    name: 'Professional Yoga Mat',
    description: 'Extra thick 6mm yoga mat with non-slip surface and alignment guides. Eco-friendly TPE material, comes with carrying strap.',
    category: sports,
    price: 2999,
    discount_price: 2499,
    stock: 60,
    sku: 'SYM-PRO-01',
    weight: 1.2,
    dimensions: '183 x 61 x 0.6 cm',
    image_url: 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=800&q=80'
  },
  {
    name: 'Smart Fitness Watch',
    description: 'Advanced fitness tracker with heart rate monitoring, GPS, sleep tracking, and 50+ sport modes. Water resistant to 50m.',
    category: sports,
    price: 19999,
    discount_price: 17999,
    stock: 40,
    sku: 'SFW-ADV-01',
    weight: 0.045,
    dimensions: '44mm case',
    image_url: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80'
  },

  # Books & Stationery
  {
    name: 'Premium Leather Journal Set',
    description: 'Handcrafted leather journal with 200 pages of premium paper. Includes premium pen and bookmark. Perfect for professionals.',
    category: books,
    price: 2999,
    discount_price: 2499,
    stock: 75,
    sku: 'BLJ-PRM-01',
    weight: 0.6,
    dimensions: 'A5 (14.8 x 21 cm)',
    image_url: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800&q=80'
  },
  {
    name: 'Complete Art Supply Kit',
    description: 'Professional art supply kit with 72 colored pencils, 48 markers, sketching pencils, and accessories. Comes in wooden storage case.',
    category: books,
    price: 5999,
    discount_price: 4999,
    stock: 30,
    sku: 'BAS-PRO-01',
    weight: 2.5,
    dimensions: '40 x 30 x 8 cm',
    image_url: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800&q=80'
  }
]

# Create products
products_data.each do |product_data|
  product = Product.find_or_create_by!(sku: product_data[:sku]) do |p|
    p.name = product_data[:name]
    p.description = product_data[:description]
    p.category = product_data[:category]
    p.price = product_data[:price]
    p.discount_price = product_data[:discount_price]
    p.stock = product_data[:stock]
    p.weight = product_data[:weight]
    p.dimensions = product_data[:dimensions]
    p.status = 'active'
    p.meta_title = product_data[:name]
    p.meta_description = product_data[:description].truncate(160)
    p.tags = "#{product_data[:category].name.downcase}, trending, popular"
  end

  # Create delivery rules for each product
  # Default rule - available everywhere with standard delivery
  product.delivery_rules.find_or_create_by!(rule_type: 'everywhere') do |rule|
    rule.location_data = nil # No location data needed for everywhere
    rule.is_excluded = false
    rule.delivery_days = 5
    rule.delivery_charge = 0 # Free delivery by default
  end

  # Express delivery for major cities
  major_cities = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad', 'Pune', 'Ahmedabad']
  product.delivery_rules.find_or_create_by!(rule_type: 'city') do |rule|
    rule.location_data = major_cities.to_json
    rule.is_excluded = false
    rule.delivery_days = 2
    rule.delivery_charge = 99
  end

  # Premium delivery for select pincodes
  premium_pincodes = ['400001', '110001', '560001', '600001', '700001']
  product.delivery_rules.find_or_create_by!(rule_type: 'pincode') do |rule|
    rule.location_data = premium_pincodes.to_json
    rule.is_excluded = false
    rule.delivery_days = 1
    rule.delivery_charge = 199
  end

  puts "Created product: #{product.name}"
end

puts "✅ Successfully created #{Product.count} products with delivery rules!"

# Create some attractive banners
banners_data = [
  {
    title: 'Year End Sale - Up to 70% Off',
    description: 'Biggest sale of the year on electronics, fashion, and more!',
    redirect_link: 'https://example.com/products?sale=true',
    display_location: 'home',
    status: true,
    display_order: 1
  },
  {
    title: 'New iPhone 15 Series Available',
    description: 'Get the latest iPhone with exclusive launch offers',
    redirect_link: 'https://example.com/products?category=smartphones',
    display_location: 'dashboard',
    status: true,
    display_order: 2
  },
  {
    title: 'Free Shipping on Orders Above ₹999',
    description: 'Shop more, save more on delivery charges',
    redirect_link: 'https://example.com/products',
    display_location: 'sidebar',
    status: true,
    display_order: 3
  }
]

banners_data.each do |banner_data|
  banner = Banner.find_or_create_by!(title: banner_data[:title]) do |b|
    b.description = banner_data[:description]
    b.redirect_link = banner_data[:redirect_link]
    b.display_location = banner_data[:display_location]
    b.display_start_date = Date.today
    b.display_end_date = 3.months.from_now
    b.status = banner_data[:status]
    b.display_order = banner_data[:display_order]
  end
  puts "Created banner: #{banner.title}"
end

# Create coupons
coupons_data = [
  {
    code: 'WELCOME20',
    description: 'Get 20% off on your first order',
    discount_type: 'percentage',
    discount_value: 20,
    minimum_amount: 1000,
    maximum_discount: 2000,
    usage_limit: 100
  },
  {
    code: 'FLAT500',
    description: 'Flat ₹500 off on orders above ₹5000',
    discount_type: 'fixed',
    discount_value: 500,
    minimum_amount: 5000,
    usage_limit: 50
  },
  {
    code: 'ELECTRONICS10',
    description: '10% off on all electronics',
    discount_type: 'percentage',
    discount_value: 10,
    minimum_amount: 2000,
    maximum_discount: 5000,
    usage_limit: 200,
    applicable_categories: [electronics.id].to_json
  }
]

coupons_data.each do |coupon_data|
  coupon = Coupon.find_or_create_by!(code: coupon_data[:code]) do |c|
    c.description = coupon_data[:description]
    c.discount_type = coupon_data[:discount_type]
    c.discount_value = coupon_data[:discount_value]
    c.minimum_amount = coupon_data[:minimum_amount]
    c.maximum_discount = coupon_data[:maximum_discount]
    c.usage_limit = coupon_data[:usage_limit]
    c.used_count = 0
    c.valid_from = Date.today
    c.valid_until = 6.months.from_now
    c.status = true
    c.applicable_categories = coupon_data[:applicable_categories] if coupon_data[:applicable_categories]
  end
  puts "Created coupon: #{coupon.code}"
end

puts "✅ Sample ecommerce data created successfully!"