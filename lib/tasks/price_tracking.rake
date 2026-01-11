namespace :price_tracking do
  desc "Update daily price tracking for all products"
  task update_daily_prices: :environment do
    puts "Starting daily price tracking update..."

    updated_count = 0
    error_count = 0

    Product.find_each do |product|
      begin
        # Only update if it's a new day or first time
        if product.last_price_update.nil? || product.last_price_update < Date.current.beginning_of_day
          # Move today's price to yesterday's price
          if product.today_price.present?
            product.yesterday_price = product.today_price
          else
            product.yesterday_price = product.price
          end

          # Set current price as today's price
          product.today_price = product.price
          product.last_price_update = Time.current

          # Calculate price change percentage
          if product.yesterday_price.present? && product.yesterday_price > 0
            price_change = ((product.today_price - product.yesterday_price) / product.yesterday_price * 100).round(2)
            product.price_change_percentage = price_change
          else
            product.price_change_percentage = 0
          end

          # Update price history
          history = product.get_price_history_array
          history << {
            date: Date.current.to_s,
            price: product.today_price,
            timestamp: Time.current.to_i
          }

          # Keep only last 30 days
          history = history.last(30)
          product.price_history = history.to_json

          # Save without triggering callbacks to avoid infinite loop
          product.save!(validate: false)
          updated_count += 1

          puts "✓ Updated price tracking for: #{product.name} (ID: #{product.id})"
        else
          puts "- Skipped #{product.name} (already updated today)"
        end

      rescue => e
        error_count += 1
        puts "✗ Error updating #{product.name} (ID: #{product.id}): #{e.message}"
      end
    end

    puts "\n" + "="*50
    puts "Price tracking update completed!"
    puts "Updated products: #{updated_count}"
    puts "Errors: #{error_count}"
    puts "Total products: #{Product.count}"
    puts "="*50
  end

  desc "Initialize price tracking for products without tracking data"
  task initialize_tracking: :environment do
    puts "Initializing price tracking for products..."

    initialized_count = 0

    Product.where(today_price: nil).find_each do |product|
      begin
        product.today_price = product.price
        product.yesterday_price = product.price
        product.price_change_percentage = 0
        product.last_price_update = Time.current

        # Initialize price history
        history = [{
          date: Date.current.to_s,
          price: product.price,
          timestamp: Time.current.to_i
        }]
        product.price_history = history.to_json

        product.save!(validate: false)
        initialized_count += 1

        puts "✓ Initialized price tracking for: #{product.name}"

      rescue => e
        puts "✗ Error initializing #{product.name}: #{e.message}"
      end
    end

    puts "\n" + "="*50
    puts "Price tracking initialization completed!"
    puts "Initialized products: #{initialized_count}"
    puts "="*50
  end

  desc "Simulate price changes for demonstration"
  task simulate_price_changes: :environment do
    puts "Simulating price changes for demonstration..."

    # Get some products to simulate price changes
    products = Product.active.limit(5)

    products.each do |product|
      begin
        original_price = product.price

        # Simulate random price change (-10% to +10%)
        change_percentage = rand(-10.0..10.0)
        new_price = (original_price * (1 + change_percentage / 100)).round(2)

        # Ensure minimum price
        new_price = [new_price, 1.0].max

        # Update yesterday's price first
        product.yesterday_price = product.today_price || original_price

        # Update current prices
        product.price = new_price
        product.today_price = new_price
        product.last_price_update = Time.current

        # Calculate change percentage
        if product.yesterday_price > 0
          product.price_change_percentage = ((new_price - product.yesterday_price) / product.yesterday_price * 100).round(2)
        end

        # Update price history
        history = product.get_price_history_array
        history << {
          date: Date.current.to_s,
          price: new_price,
          timestamp: Time.current.to_i,
          simulated: true
        }
        product.price_history = history.last(30).to_json

        product.save!(validate: false)

        trend_icon = case
                    when change_percentage > 0
                      "📈"
                    when change_percentage < 0
                      "📉"
                    else
                      "➡️"
                    end

        puts "#{trend_icon} #{product.name}: ₹#{original_price} → ₹#{new_price} (#{change_percentage > 0 ? '+' : ''}#{change_percentage.round(2)}%)"

      rescue => e
        puts "✗ Error simulating price change for #{product.name}: #{e.message}"
      end
    end

    puts "\nPrice simulation completed!"
  end

  desc "Generate sample price history for last 7 days"
  task generate_sample_history: :environment do
    puts "Generating sample price history for demonstration..."

    Product.active.limit(3).each do |product|
      begin
        history = []
        base_price = product.price

        # Generate price history for last 7 days
        (6.downto(0)).each do |days_ago|
          date = days_ago.days.ago.to_date

          # Simulate realistic price fluctuations
          fluctuation = rand(-5.0..5.0) / 100  # ±5%
          day_price = (base_price * (1 + fluctuation)).round(2)

          history << {
            date: date.to_s,
            price: day_price,
            timestamp: date.beginning_of_day.to_i
          }
        end

        # Update product with generated history
        product.price_history = history.to_json
        product.yesterday_price = history[-2][:price] if history.length > 1
        product.today_price = history.last[:price]
        product.last_price_update = Time.current

        # Calculate price change
        if product.yesterday_price && product.yesterday_price > 0
          product.price_change_percentage = ((product.today_price - product.yesterday_price) / product.yesterday_price * 100).round(2)
        end

        product.save!(validate: false)

        puts "✓ Generated 7-day price history for: #{product.name}"

      rescue => e
        puts "✗ Error generating history for #{product.name}: #{e.message}"
      end
    end

    puts "\nSample price history generation completed!"
  end

  desc "Clean up old price history (older than 30 days)"
  task cleanup_history: :environment do
    puts "Cleaning up old price history data..."

    cleaned_count = 0

    Product.where.not(price_history: [nil, ""]).find_each do |product|
      begin
        history = product.get_price_history_array

        # Keep only last 30 days
        cutoff_timestamp = 30.days.ago.to_i
        filtered_history = history.select { |entry| entry[:timestamp].to_i > cutoff_timestamp }

        if filtered_history.length < history.length
          product.price_history = filtered_history.to_json
          product.save!(validate: false)
          cleaned_count += 1

          puts "✓ Cleaned price history for: #{product.name} (removed #{history.length - filtered_history.length} old entries)"
        end

      rescue => e
        puts "✗ Error cleaning history for #{product.name}: #{e.message}"
      end
    end

    puts "\nPrice history cleanup completed!"
    puts "Cleaned products: #{cleaned_count}"
  end
end