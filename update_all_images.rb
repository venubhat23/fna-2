#!/usr/bin/env ruby

require 'open-uri'

puts '🖼️  Updating ALL products and categories with the same image...'
puts '=' * 60

# Your provided image URL
image_url = 'https://images.ctfassets.net/8pjzui68f1rh/6JhiYvk2HRGI7G57yRSEUo/70d47d6be87edbc4a1c988ac21146c4f/a2-milk-success-story.jpg?w=1200&h=801&q=100&fm=webp'

updated_products = 0
updated_categories = 0
error_count = 0

puts "Using image URL: #{image_url}"
puts "\n🛍️  Updating Product Images:"
puts '-' * 30

begin
  # Update all products
  Product.find_each do |product|
    begin
      puts "📥 Updating: #{product.name}"

      image_data = URI.open(image_url)
      product.images.purge if product.images.attached?

      product.images.attach(
        io: image_data,
        filename: "#{product.name.parameterize}.jpg",
        content_type: 'image/jpeg'
      )

      puts "✅ Updated: #{product.name}"
      updated_products += 1
    rescue => e
      puts "❌ Error updating #{product.name}: #{e.message}"
      error_count += 1
    end
  end

  puts "\n📂 Updating Category Images:"
  puts '-' * 30

  # Update all categories
  Category.find_each do |category|
    begin
      puts "📥 Updating: #{category.name}"

      image_data = URI.open(image_url)
      category.image.purge if category.image.attached?

      category.image.attach(
        io: image_data,
        filename: "#{category.name.parameterize}.jpg",
        content_type: 'image/jpeg'
      )

      puts "✅ Updated: #{category.name}"
      updated_categories += 1
    rescue => e
      puts "❌ Error updating #{category.name}: #{e.message}"
      error_count += 1
    end
  end

rescue => e
  puts "❌ Database connection error: #{e.message}"
  puts "Please check your database connection and try again."
end

puts "\n📊 Final Update Summary:"
puts "Successfully updated products: #{updated_products}"
puts "Successfully updated categories: #{updated_categories}"
puts "Total errors: #{error_count}"
puts "\n🎉 Image update completed!"