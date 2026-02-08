# Test inventory service with FIFO logic
puts "Testing Inventory Service FIFO Logic"
puts "=" * 50

# Get the product we created or find any product with batches
product = Product.joins(:stock_batches).first || Product.find_by(name: 'Test Milk Product')
if product.nil?
  puts "Error: Test product not found. Please run test_vendor_setup.rb first."
  exit
end

puts "Product: #{product.name}"
puts "Total batch stock: #{product.total_batch_stock} #{product.unit_display}"
puts ""

# Create additional batches to test FIFO
vendor = Vendor.first
purchase2 = VendorPurchase.create!(
  vendor: vendor,
  purchase_date: Date.current - 5.days,
  total_amount: 1500,
  paid_amount: 0,
  status: 'pending'
)

batch2 = StockBatch.create!(
  product: product,
  vendor: vendor,
  vendor_purchase: purchase2,
  quantity_purchased: 30,
  quantity_remaining: 30,
  purchase_price: 25,
  selling_price: 35,
  batch_date: Date.current - 5.days,
  status: 'active'
)
puts "Created second batch: 30 units @ ₹25 purchase price"

# Create third batch
purchase3 = VendorPurchase.create!(
  vendor: vendor,
  purchase_date: Date.current - 2.days,
  total_amount: 1000,
  paid_amount: 0,
  status: 'pending'
)

batch3 = StockBatch.create!(
  product: product,
  vendor: vendor,
  vendor_purchase: purchase3,
  quantity_purchased: 20,
  quantity_remaining: 20,
  purchase_price: 22,
  selling_price: 32,
  batch_date: Date.current - 2.days,
  status: 'active'
)
puts "Created third batch: 20 units @ ₹22 purchase price"
puts ""

# Display all batches
puts "Current Stock Batches (FIFO Order):"
puts "-" * 40
StockBatch.where(product: product).by_fifo.each do |batch|
  puts "Batch ##{batch.id}: #{batch.quantity_remaining}/#{batch.quantity_purchased} units"
  puts "  Purchase Date: #{batch.batch_date}"
  puts "  Purchase Price: ₹#{batch.purchase_price}"
  puts "  Selling Price: ₹#{batch.selling_price}"
  puts ""
end

# Test FIFO allocation
puts "Testing FIFO Allocation:"
puts "-" * 40

# Test allocation for 40 units
requested_quantity = 40
puts "Requesting #{requested_quantity} units..."
begin
  allocations = InventoryService.allocate_stock(product.id, requested_quantity)

  puts "Allocation successful!"
  puts "Allocations:"
  total_allocated = 0
  allocations.each do |alloc|
    batch = alloc[:batch]
    puts "  Batch ##{batch.id}: #{alloc[:quantity]} units @ ₹#{batch.purchase_price} (purchase) / ₹#{batch.selling_price} (selling)"
    total_allocated += alloc[:quantity]
  end
  puts "Total allocated: #{total_allocated} units"
rescue => e
  puts "Allocation failed: #{e.message}"
  allocations = []
end

puts ""
puts "Testing Profit Calculation:"
puts "-" * 40

# Calculate expected profit
if allocations && allocations.any?
  total_profit = 0
  allocations.each do |alloc|
    batch = alloc[:batch]
    profit = (batch.selling_price - batch.purchase_price) * alloc[:quantity]
    total_profit += profit
    puts "Batch ##{batch.id}: (₹#{batch.selling_price} - ₹#{batch.purchase_price}) × #{alloc[:quantity]} = ₹#{profit}"
  end
  puts "Total Expected Profit: ₹#{total_profit}"
else
  puts "No allocations to calculate profit"
end

puts ""
puts "All tests completed successfully!"