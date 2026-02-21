#!/usr/bin/env ruby

# Subscription Template Bulk Import and Monthly Task Creation Script
# Usage: rails runner subscription_bulk_import.rb

puts "🚀 Starting Subscription Template Bulk Import Script"
puts "=" * 60

# Configuration
CURRENT_MONTH = Date.current.beginning_of_month
CURRENT_MONTH_END = Date.current.end_of_month
DAYS_IN_MONTH = (CURRENT_MONTH_END - CURRENT_MONTH + 1).to_i

puts "📅 Processing for month: #{CURRENT_MONTH.strftime('%B %Y')}"
puts "📊 Total days in month: #{DAYS_IN_MONTH}"
puts ""

# Sample master data - Replace this with your actual data or CSV import
MASTER_DATA = [
  {
    customer_name: "Customer 1",
    customer_mobile: "9999999991",
    customer_email: "customer1@example.com",
    product_name: "Fresh Milk",
    quantity: 1.0,
    unit: "liter",
    price: 60.0,
    delivery_time: "07:00",
    delivery_person_name: "Delivery Person A",
    delivery_person_mobile: "8888888881"
  },
  {
    customer_name: "Customer 2",
    customer_mobile: "9999999992",
    customer_email: "customer2@example.com",
    product_name: "Fresh Milk",
    quantity: 0.5,
    unit: "liter",
    price: 30.0,
    delivery_time: "07:30",
    delivery_person_name: "Delivery Person B",
    delivery_person_mobile: "8888888882"
  },
  {
    customer_name: "Customer 3",
    customer_mobile: "9999999993",
    customer_email: "customer3@example.com",
    product_name: "Fresh Milk",
    quantity: 2.0,
    unit: "liter",
    price: 120.0,
    delivery_time: "08:00",
    delivery_person_name: "Delivery Person A",
    delivery_person_mobile: "8888888881"
  }
]

class SubscriptionBulkProcessor
  def self.process_templates
    puts "🔄 Processing #{MASTER_DATA.length} subscription templates..."

    created_subscriptions = 0
    created_delivery_tasks = 0
    errors = []

    MASTER_DATA.each_with_index do |data, index|
      begin
        puts "\n📋 Processing template #{index + 1}: #{data[:customer_name]} - #{data[:quantity]}#{data[:unit]} #{data[:product_name]}"

        # Find or create customer
        customer = find_or_create_customer(data)
        next unless customer

        # Find or create product
        product = find_or_create_product(data)
        next unless product

        # Find or create delivery person
        delivery_person = find_or_create_delivery_person(data)

        # Create subscription template
        template = create_subscription_template(customer, product, delivery_person, data)
        next unless template

        # Create monthly subscription
        subscription = create_monthly_subscription(customer, product, template, data)
        if subscription
          created_subscriptions += 1

          # Create delivery tasks for entire month
          tasks_created = create_monthly_delivery_tasks(subscription, customer, product, delivery_person, data)
          created_delivery_tasks += tasks_created

          puts "✅ Created subscription and #{tasks_created} delivery tasks for #{customer.first_name}"
        end

      rescue => e
        error_msg = "❌ Error processing #{data[:customer_name]}: #{e.message}"
        errors << error_msg
        puts error_msg
        puts e.backtrace.first(3).join("\n") if Rails.env.development?
      end
    end

    print_summary(created_subscriptions, created_delivery_tasks, errors)
  end

  private

  def self.find_or_create_customer(data)
    customer = Customer.find_by(mobile: data[:customer_mobile]) ||
               Customer.find_by(email: data[:customer_email])

    unless customer
      puts "👤 Creating new customer: #{data[:customer_name]}"

      name_parts = data[:customer_name].split(' ')
      customer = Customer.create!(
        first_name: name_parts.first,
        last_name: name_parts.length > 1 ? name_parts[1..-1].join(' ') : '',
        mobile: data[:customer_mobile],
        email: data[:customer_email],
        status: true
      )
      puts "✅ Customer created with ID: #{customer.id}"
    else
      puts "✅ Found existing customer: #{customer.display_name} (ID: #{customer.id})"
    end

    customer
  end

  def self.find_or_create_product(data)
    product = Product.find_by(name: data[:product_name])

    unless product
      puts "📦 Creating new product: #{data[:product_name]}"

      # Find or create a category
      category = Category.find_by(name: 'Dairy') || Category.create!(
        name: 'Dairy',
        description: 'Dairy products',
        status: true,
        display_order: 1
      )

      product = Product.create!(
        name: data[:product_name],
        description: "Fresh #{data[:product_name].downcase}",
        category_id: category.id,
        price: data[:price],
        stock: 1000,
        status: 'active',
        sku: "MILK-#{Time.current.to_i}",
        unit: data[:unit],
        is_subscription_enabled: true,
        product_type: 'subscription'
      )
      puts "✅ Product created with ID: #{product.id}"
    else
      puts "✅ Found existing product: #{product.name} (ID: #{product.id})"
    end

    product
  end

  def self.find_or_create_delivery_person(data)
    return nil unless data[:delivery_person_name] && data[:delivery_person_mobile]

    delivery_person = DeliveryPerson.find_by(mobile: data[:delivery_person_mobile])

    unless delivery_person
      puts "🚚 Creating new delivery person: #{data[:delivery_person_name]}"

      name_parts = data[:delivery_person_name].split(' ')
      delivery_person = DeliveryPerson.create!(
        first_name: name_parts.first,
        last_name: name_parts.length > 1 ? name_parts[1..-1].join(' ') : '',
        mobile: data[:delivery_person_mobile],
        email: "#{data[:delivery_person_name].gsub(' ', '.').downcase}@delivery.com",
        vehicle_type: 'bike',
        status: true,
        joining_date: Date.current,
        delivery_areas: 'City Center'
      )
      puts "✅ Delivery person created with ID: #{delivery_person.id}"
    else
      puts "✅ Found existing delivery person: #{delivery_person.first_name} #{delivery_person.last_name} (ID: #{delivery_person.id})"
    end

    delivery_person
  end

  def self.create_subscription_template(customer, product, delivery_person, data)
    template_name = "#{customer.display_name} - #{data[:quantity]}#{data[:unit]} #{product.name}"

    template = SubscriptionTemplate.find_by(
      customer: customer,
      product: product,
      template_name: template_name
    )

    unless template
      puts "📝 Creating subscription template: #{template_name}"

      template = SubscriptionTemplate.create!(
        customer: customer,
        product: product,
        delivery_person: delivery_person,
        quantity: data[:quantity],
        unit: data[:unit],
        price: data[:price],
        delivery_time: data[:delivery_time],
        is_active: true,
        template_name: template_name,
        notes: "Auto-generated from bulk import"
      )
      puts "✅ Template created with ID: #{template.id}"
    else
      puts "✅ Found existing template: #{template.template_name} (ID: #{template.id})"
    end

    template
  end

  def self.create_monthly_subscription(customer, product, template, data)
    # Check if subscription already exists for this month
    existing_subscription = MilkSubscription.where(
      customer: customer,
      product: product,
      start_date: CURRENT_MONTH,
      end_date: CURRENT_MONTH_END
    ).first

    if existing_subscription
      puts "✅ Found existing subscription for this month (ID: #{existing_subscription.id})"
      return existing_subscription
    end

    puts "📅 Creating monthly subscription from #{CURRENT_MONTH.strftime('%d/%m/%Y')} to #{CURRENT_MONTH_END.strftime('%d/%m/%Y')}"

    subscription = MilkSubscription.create!(
      customer: customer,
      product: product,
      quantity: data[:quantity],
      unit: data[:unit],
      start_date: CURRENT_MONTH,
      end_date: CURRENT_MONTH_END,
      delivery_time: data[:delivery_time],
      is_active: true
    )

    puts "✅ Monthly subscription created with ID: #{subscription.id}"
    subscription
  end

  def self.create_monthly_delivery_tasks(subscription, customer, product, delivery_person, data)
    tasks_created = 0

    puts "🗓️  Creating daily delivery tasks for the month..."

    (CURRENT_MONTH..CURRENT_MONTH_END).each do |date|
      # Skip if task already exists for this date
      existing_task = MilkDeliveryTask.find_by(
        subscription: subscription,
        customer: customer,
        delivery_date: date
      )

      if existing_task
        next # Skip this date
      end

      begin
        task = MilkDeliveryTask.create!(
          subscription: subscription,
          customer: customer,
          product: product,
          delivery_person: delivery_person,
          quantity: data[:quantity],
          delivery_date: date,
          status: 'pending'
        )

        tasks_created += 1

        # Print progress every 7 days
        if tasks_created % 7 == 0
          puts "   📋 Created #{tasks_created} tasks so far..."
        end

      rescue => e
        puts "   ❌ Failed to create task for #{date.strftime('%d/%m/%Y')}: #{e.message}"
      end
    end

    puts "✅ Created #{tasks_created} delivery tasks for #{customer.first_name}"
    tasks_created
  end

  def self.print_summary(created_subscriptions, created_delivery_tasks, errors)
    puts "\n" + "=" * 60
    puts "📊 BULK IMPORT SUMMARY"
    puts "=" * 60
    puts "✅ Subscriptions created: #{created_subscriptions}"
    puts "✅ Delivery tasks created: #{created_delivery_tasks}"
    puts "❌ Errors encountered: #{errors.length}"
    puts ""

    if errors.any?
      puts "🚨 ERROR DETAILS:"
      errors.each_with_index do |error, index|
        puts "#{index + 1}. #{error}"
      end
      puts ""
    end

    puts "📈 STATISTICS:"
    puts "- Average tasks per subscription: #{created_subscriptions > 0 ? (created_delivery_tasks.to_f / created_subscriptions).round(1) : 0}"
    puts "- Total master templates processed: #{MASTER_DATA.length}"
    puts "- Success rate: #{MASTER_DATA.length > 0 ? ((created_subscriptions.to_f / MASTER_DATA.length) * 100).round(1) : 0}%"
    puts ""

    puts "🎉 Bulk import completed successfully!"
    puts "=" * 60
  end
end

# Add CSV import functionality
class CSVImporter
  def self.import_from_csv(file_path)
    unless File.exist?(file_path)
      puts "❌ CSV file not found: #{file_path}"
      return
    end

    require 'csv'

    puts "📁 Importing from CSV: #{file_path}"

    csv_data = []
    CSV.foreach(file_path, headers: true) do |row|
      csv_data << {
        customer_name: row['customer_name'],
        customer_mobile: row['customer_mobile'],
        customer_email: row['customer_email'],
        product_name: row['product_name'],
        quantity: row['quantity'].to_f,
        unit: row['unit'],
        price: row['price'].to_f,
        delivery_time: row['delivery_time'],
        delivery_person_name: row['delivery_person_name'],
        delivery_person_mobile: row['delivery_person_mobile']
      }
    end

    puts "✅ Loaded #{csv_data.length} records from CSV"

    # Replace MASTER_DATA with CSV data
    Object.send(:remove_const, :MASTER_DATA)
    Object.const_set(:MASTER_DATA, csv_data)

    SubscriptionBulkProcessor.process_templates
  end
end

# Generate sample CSV file
def generate_sample_csv
  csv_path = Rails.root.join('subscription_master_data.csv')

  require 'csv'

  CSV.open(csv_path, 'w', write_headers: true, headers: [
    'customer_name', 'customer_mobile', 'customer_email', 'product_name',
    'quantity', 'unit', 'price', 'delivery_time',
    'delivery_person_name', 'delivery_person_mobile'
  ]) do |csv|
    MASTER_DATA.each do |data|
      csv << [
        data[:customer_name],
        data[:customer_mobile],
        data[:customer_email],
        data[:product_name],
        data[:quantity],
        data[:unit],
        data[:price],
        data[:delivery_time],
        data[:delivery_person_name],
        data[:delivery_person_mobile]
      ]
    end
  end

  puts "📋 Sample CSV file generated: #{csv_path}"
  puts "You can modify this file and then import it using:"
  puts "rails runner \"CSVImporter.import_from_csv('#{csv_path}')\""
end

# Main execution
if ARGV.empty?
  puts "🚀 Running with sample master data..."
  SubscriptionBulkProcessor.process_templates
elsif ARGV[0] == 'generate_csv'
  generate_sample_csv
elsif ARGV[0] == 'import_csv' && ARGV[1]
  CSVImporter.import_from_csv(ARGV[1])
else
  puts "Usage:"
  puts "rails runner subscription_bulk_import.rb                           # Run with sample data"
  puts "rails runner subscription_bulk_import.rb generate_csv              # Generate sample CSV"
  puts "rails runner subscription_bulk_import.rb import_csv <file_path>    # Import from CSV"
end