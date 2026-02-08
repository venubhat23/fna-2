# Test creating a vendor
vendor = Vendor.create!(
  name: 'Test Vendor',
  phone: '9876543210',
  email: 'vendor@test.com',
  address: '123 Test Street',
  payment_type: 'Credit',
  opening_balance: 0,
  status: true
)
puts "Vendor created: #{vendor.name}"

# Test creating a product with vendor fields
product = Product.first || Product.create!(
  name: 'Test Product',
  category: Category.first || Category.create!(name: 'Test Category'),
  price: 100,
  original_price: 100,
  product_type: 'regular',
  unit_type: 'Kg',
  minimum_stock_alert: 10,
  default_selling_price: 150
)
puts "Product: #{product.name}"

# Test creating a vendor purchase
purchase = VendorPurchase.create!(
  vendor: vendor,
  purchase_date: Date.current,
  total_amount: 1000,
  paid_amount: 0,
  status: 'pending'
)
puts "Vendor Purchase created with ID: #{purchase.id}"

# Test creating purchase items
item = VendorPurchaseItem.create!(
  vendor_purchase: purchase,
  product: product,
  quantity: 50,
  purchase_price: 20,
  selling_price: 30,
  line_total: 1000
)
puts "Purchase Item created: #{item.quantity} #{product.unit_type}"

# Test creating stock batch
batch = StockBatch.create!(
  product: product,
  vendor: vendor,
  vendor_purchase: purchase,
  quantity_purchased: 50,
  quantity_remaining: 50,
  purchase_price: 20,
  selling_price: 30,
  batch_date: Date.current,
  status: 'active'
)
puts "Stock Batch created with ID: #{batch.id}"

puts 'All models tested successfully!'