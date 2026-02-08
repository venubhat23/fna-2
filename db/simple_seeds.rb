# Simple seeds for dashboard demo
puts "Creating simple dashboard data..."

# Create categories if none exist
if Category.count == 0
  ['Electronics', 'Clothing', 'Books', 'Home'].each do |name|
    Category.create!(name: name, status: true)
  end
  puts "✅ Created categories"
end

# Create products if none exist
if Product.count == 0
  Category.all.each do |category|
    3.times do |i|
      Product.create!(
        name: "#{category.name} Product #{i+1}",
        category: category,
        price: rand(1000..50000),
        stock: rand(5..100),
        status: 'active',
        sku: "#{category.name.upcase[0..2]}#{i+1}"
      )
    end
  end
  puts "✅ Created products"
end

# Create customers if none exist
if Customer.count == 0
  5.times do |i|
    Customer.create!(
      first_name: "Customer#{i+1}",
      last_name: "User#{i+1}",
      email: "customer#{i+1}@test.com",
      mobile: "987654321#{i}",
      customer_type: 'individual',
      password: 'password123',
      password_confirmation: 'password123',
      state: ['Karnataka', 'Maharashtra', 'Tamil Nadu'][i % 3],
      city: ['Bangalore', 'Mumbai', 'Chennai'][i % 3]
    )
  end
  puts "✅ Created customers"
end

# Create bookings if none exist
if Booking.count == 0
  Customer.all.each_with_index do |customer, i|
    Booking.create!(
      customer: customer,
      customer_name: "#{customer.first_name} #{customer.last_name}",
      customer_email: customer.email,
      booking_number: "BK#{i+1}",
      booking_date: Date.today - rand(0..30).days,
      status: 'completed',
      payment_status: 'paid',
      payment_method: 'cash',
      subtotal: 5000 + (i * 1000),
      total_amount: 5900 + (i * 1180)
    )
  end
  puts "✅ Created bookings"
end

puts "\n🎉 Dashboard demo data created!"
puts "📊 Dashboard ready at: http://localhost:3000"
puts "📈 #{Product.count} products, #{Customer.count} customers, #{Booking.count} bookings"