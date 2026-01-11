class DeliveryValidationService
  def initialize(product, pincode)
    @product = product
    @pincode = pincode.to_s.strip
  end

  def validate
    return error_result('Product not found') unless @product
    return error_result('Invalid pincode') unless valid_pincode?
    return error_result('Product is not active') unless @product.active?
    return error_result('Product is out of stock') unless @product.in_stock?

    delivery_info = check_delivery_availability

    if delivery_info[:available]
      success_result(delivery_info)
    else
      error_result('Delivery not available for this pincode')
    end
  end

  def self.validate_product_delivery(product, pincode)
    new(product, pincode).validate
  end

  def self.validate_cart_delivery(cart_items, pincode)
    results = []
    total_delivery_charge = 0
    max_delivery_days = 0

    cart_items.each do |item|
      product = item.is_a?(Hash) ? Product.find(item[:product_id]) : item.product
      quantity = item.is_a?(Hash) ? item[:quantity] : item.quantity

      result = validate_product_delivery(product, pincode)

      if result[:success]
        delivery_info = result[:data]
        total_delivery_charge += delivery_info[:delivery_charge]
        max_delivery_days = [max_delivery_days, delivery_info[:delivery_days]].max

        results << {
          product_id: product.id,
          product_name: product.name,
          quantity: quantity,
          deliverable: true,
          delivery_days: delivery_info[:delivery_days],
          delivery_charge: delivery_info[:delivery_charge]
        }
      else
        results << {
          product_id: product.id,
          product_name: product.name,
          quantity: quantity,
          deliverable: false,
          error: result[:message]
        }
      end
    end

    # Check if all products are deliverable
    all_deliverable = results.all? { |r| r[:deliverable] }

    {
      success: all_deliverable,
      data: {
        total_delivery_charge: total_delivery_charge,
        estimated_delivery_days: max_delivery_days,
        items: results
      },
      message: all_deliverable ? 'All items can be delivered' : 'Some items cannot be delivered'
    }
  end

  private

  def valid_pincode?
    @pincode.length == 6 && @pincode.match?(/\A\d{6}\z/)
  end

  def check_delivery_availability
    delivery_rules = @product.delivery_rules.includes(:product)

    return default_delivery_info if delivery_rules.empty?

    # Check for 'everywhere' rules first
    all_rule = delivery_rules.find { |rule| rule.rule_type == 'everywhere' }
    return rule_delivery_info(all_rule) if all_rule

    # Check for specific rules
    matching_rule = find_matching_rule(delivery_rules)
    return rule_delivery_info(matching_rule) if matching_rule

    # Check for state/city rules (simplified - you'd need actual state/city data)
    state_city_rule = check_state_city_rules(delivery_rules)
    return rule_delivery_info(state_city_rule) if state_city_rule

    # No matching rules found
    { available: false }
  end

  def find_matching_rule(delivery_rules)
    # Check pincode-specific rules
    pincode_rules = delivery_rules.select { |rule| rule.rule_type == 'pincode' }

    pincode_rules.find do |rule|
      begin
        location_data = JSON.parse(rule.location_data || '[]')
        location_data.include?(@pincode)
      rescue JSON::ParserError
        false
      end
    end
  end

  def check_state_city_rules(delivery_rules)
    # This is a simplified implementation
    # In a real application, you'd have a mapping of pincodes to states/cities
    # For now, we'll just check if there are any state/city rules and return the first one

    state_rules = delivery_rules.select { |rule| rule.rule_type == 'state' }
    city_rules = delivery_rules.select { |rule| rule.rule_type == 'city' }

    # You would implement actual pincode-to-state/city mapping here
    # For demonstration, we'll return nil (no match)
    nil
  end

  def rule_delivery_info(rule)
    return { available: false } if rule.is_excluded?

    {
      available: true,
      delivery_days: rule.delivery_days || 7,
      delivery_charge: rule.delivery_charge || 0,
      rule_type: rule.rule_type
    }
  end

  def default_delivery_info
    # Default delivery when no rules are set
    {
      available: false
    }
  end

  def success_result(data)
    {
      success: true,
      data: data,
      message: 'Delivery available'
    }
  end

  def error_result(message)
    {
      success: false,
      data: nil,
      message: message
    }
  end
end