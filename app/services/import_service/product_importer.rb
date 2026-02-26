module ImportService
  class ProductImporter
    require 'csv'

    def initialize(uploaded_file)
      @uploaded_file = uploaded_file
      @imported_count = 0
      @skipped_count = 0
      @errors = []
    end

    def import
      return { success: false, error: 'No file provided' } unless @uploaded_file

      begin
        csv_content = @uploaded_file.read
        @uploaded_file.rewind

        csv_data = CSV.parse(csv_content, headers: true)

        # Validate CSV first
        validator = CsvValidator.new(@uploaded_file, 'products')
        validation_result = validator.validate

        unless validation_result[:success]
          return { success: false, error: validation_result[:error] }
        end

        Product.transaction do
          csv_data.each_with_index do |row, index|
            begin
              process_product_row(row, index + 2)
            rescue => e
              @errors << "Row #{index + 2}: #{e.message}"
              @skipped_count += 1
            end
          end
        end

        {
          success: true,
          imported_count: @imported_count,
          skipped_count: @skipped_count,
          errors: @errors
        }

      rescue CSV::MalformedCSVError => e
        { success: false, error: "Invalid CSV format: #{e.message}" }
      rescue => e
        Rails.logger.error "Product import error: #{e.message}"
        { success: false, error: e.message }
      end
    end

    private

    def process_product_row(row, row_number)
      # Check if product already exists by SKU or name
      existing_product = nil

      if get_row_value(row, 'sku').present?
        existing_product = Product.find_by(sku: get_row_value(row, 'sku').to_s.strip)
      end

      if existing_product.nil?
        existing_product = Product.find_by(name: get_row_value(row, 'name').to_s.strip)
      end

      if existing_product
        @errors << "Row #{row_number}: Product with name '#{get_row_value(row, 'name')}' or SKU '#{get_row_value(row, 'sku')}' already exists"
        @skipped_count += 1
        return
      end

      # Find or create category
      category = find_or_create_category_from_row(row)

      # Prepare product parameters
      product_params = {
        name: get_row_value(row, 'name'),
        description: get_row_value(row, 'description'),
        category_id: category&.id,
        price: parse_decimal(get_row_value(row, 'price')),
        discount_price: parse_decimal(get_row_value(row, 'discount_price')),
        stock: parse_integer(get_row_value(row, 'stock')) || 0,
        status: parse_status(get_row_value(row, 'status')),
        sku: generate_sku(row),
        weight: parse_decimal(get_row_value(row, 'weight')),
        dimensions: get_row_value(row, 'dimensions'),
        gst_enabled: parse_boolean(get_row_value(row, 'gst_enabled')),
        gst_percentage: parse_decimal(get_row_value(row, 'gst_percentage')),
        buying_price: parse_decimal(get_row_value(row, 'buying_price')),
        product_type: parse_product_type(get_row_value(row, 'product_type')),
        is_subscription_enabled: parse_boolean(get_row_value(row, 'is_subscription_enabled')),
        unit_type: parse_unit_type(get_row_value(row, 'unit_type'))
      }

      # Calculate GST amounts if GST is enabled
      if product_params[:gst_enabled] && product_params[:price] && product_params[:gst_percentage]
        price = product_params[:price]
        gst_rate = product_params[:gst_percentage] / 100

        product_params[:gst_amount] = price * gst_rate
        product_params[:final_amount_with_gst] = price + product_params[:gst_amount]

        # For India, split GST into CGST and SGST (9% each for 18% GST)
        if product_params[:gst_percentage] == 18
          product_params[:cgst_percentage] = 9
          product_params[:sgst_percentage] = 9
          product_params[:cgst_amount] = product_params[:gst_amount] / 2
          product_params[:sgst_amount] = product_params[:gst_amount] / 2
        elsif product_params[:gst_percentage] == 5
          product_params[:cgst_percentage] = 2.5
          product_params[:sgst_percentage] = 2.5
          product_params[:cgst_amount] = product_params[:gst_amount] / 2
          product_params[:sgst_amount] = product_params[:gst_amount] / 2
        end
      end

      # Set price tracking fields
      product_params[:today_price] = product_params[:price]
      product_params[:last_price_update] = Time.current

      product = Product.create!(product_params)

      @imported_count += 1
    end

    def find_or_create_category_from_row(row)
      # Try category_id first, then category_name
      if get_row_value(row, 'category_id').present?
        begin
          category_id = Integer(get_row_value(row, 'category_id'))
          return Category.find(category_id)
        rescue ArgumentError, ActiveRecord::RecordNotFound
          # Fall through to category_name method
        end
      end

      category_name = get_row_value(row, 'category_name')
      find_or_create_category(category_name)
    end

    def find_or_create_category(category_name)
      return nil if category_name.blank?

      category_name = category_name.to_s.strip
      existing_category = Category.find_by(name: category_name)

      if existing_category
        existing_category
      else
        Category.create!(
          name: category_name,
          status: true,
          display_order: Category.count + 1
        )
      end
    end

    def generate_sku(row)
      return get_row_value(row, 'sku') if get_row_value(row, 'sku').present?

      # Generate SKU from product name
      base_sku = get_row_value(row, 'name').to_s.gsub(/[^a-zA-Z0-9]/, '').upcase[0..5]
      counter = 1
      sku = "#{base_sku}#{counter.to_s.rjust(3, '0')}"

      while Product.exists?(sku: sku)
        counter += 1
        sku = "#{base_sku}#{counter.to_s.rjust(3, '0')}"
      end

      sku
    end

    def parse_decimal(decimal_string)
      return nil if decimal_string.blank?
      BigDecimal(decimal_string.to_s)
    rescue ArgumentError
      nil
    end

    def parse_integer(integer_string)
      return nil if integer_string.blank?
      Integer(integer_string.to_s)
    rescue ArgumentError
      nil
    end

    def parse_boolean(boolean_string)
      return false if boolean_string.blank?
      ['true', '1', 'yes', 'on'].include?(boolean_string.to_s.downcase)
    end

    def parse_status(status_string)
      return 'active' if status_string.blank?
      status_string.to_s.downcase == 'active' ? 'active' : 'inactive'
    end

    def parse_product_type(type_string)
      return 'Grocery' if type_string.blank?

      # Valid product types from Product model
      valid_types = Product::PRODUCT_TYPES.map(&:last)

      # Try to find exact match (case insensitive)
      type = type_string.to_s.strip
      matched_type = valid_types.find { |valid_type| valid_type.downcase == type.downcase }

      matched_type || 'Grocery' # Default to 'Grocery' if not found
    end

    def parse_unit_type(unit_string)
      return 'Piece' if unit_string.blank?

      # Valid unit types from Product model
      valid_units = ['Kg', 'Bottle', 'Box', 'Liter', 'Piece', 'Gram']

      # Try to find exact match (case insensitive)
      unit = unit_string.to_s.strip
      matched_unit = valid_units.find { |valid_unit| valid_unit.downcase == unit.downcase }

      matched_unit || 'Piece' # Default to 'Piece' if not found
    end

    # Helper method to get row values that handles headers with asterisks
    def get_row_value(row, field_name)
      # Try with asterisk first (for required fields), then without
      row["#{field_name}*"] || row[field_name]
    end
  end
end