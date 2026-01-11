class Api::DeliveryController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :set_default_format

  def check_product_delivery
    product = Product.find_by(id: params[:product_id])
    pincode = params[:pincode]

    result = DeliveryValidationService.validate_product_delivery(product, pincode)

    render json: result
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Product not found'
    }, status: 404
  rescue => e
    render json: {
      success: false,
      message: 'Internal server error'
    }, status: 500
  end

  def check_cart_delivery
    cart_items = params[:cart_items] || []
    pincode = params[:pincode]

    # Validate cart items structure
    unless cart_items.is_a?(Array) && cart_items.all? { |item| item[:product_id] && item[:quantity] }
      return render json: {
        success: false,
        message: 'Invalid cart items format'
      }, status: 400
    end

    result = DeliveryValidationService.validate_cart_delivery(cart_items, pincode)

    render json: result
  rescue => e
    render json: {
      success: false,
      message: 'Internal server error'
    }, status: 500
  end

  def available_pincodes
    product = Product.find_by(id: params[:product_id])

    unless product
      return render json: {
        success: false,
        message: 'Product not found'
      }, status: 404
    end

    pincodes = []

    product.delivery_rules.each do |rule|
      case rule.rule_type
      when 'all'
        pincodes << 'All pincodes'
        break
      when 'pincode'
        begin
          location_data = JSON.parse(rule.location_data || '[]')
          pincodes.concat(location_data)
        rescue JSON::ParserError
          # Skip invalid JSON
        end
      when 'state', 'city'
        # You would implement state/city to pincode mapping here
        pincodes << "#{rule.rule_type.humanize}: #{rule.formatted_locations}"
      end
    end

    render json: {
      success: true,
      data: {
        product_id: product.id,
        available_locations: pincodes.uniq
      }
    }
  end

  private

  def set_default_format
    request.format = :json unless params[:format]
  end
end