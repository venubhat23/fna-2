module ImportService
  class CsvValidator
    require 'csv'

    def initialize(uploaded_file, import_type)
      @uploaded_file = uploaded_file
      @import_type = import_type
      @errors = []
      @warnings = []
      @row_count = 0
      @valid_rows = 0
    end

    def validate
      return { success: false, error: 'No file provided' } unless @uploaded_file

      # Check file extension
      unless valid_file_extension?
        return { success: false, error: 'Invalid file type. Please upload a CSV file.' }
      end

      # Check file size (max 10MB)
      if @uploaded_file.size > 10.megabytes
        return { success: false, error: 'File size too large. Maximum allowed size is 10MB.' }
      end

      begin
        # Parse and validate CSV content
        csv_content = @uploaded_file.read
        @uploaded_file.rewind

        # Check if file is empty
        if csv_content.blank?
          return { success: false, error: 'File is empty' }
        end

        # Parse CSV
        csv_data = CSV.parse(csv_content, headers: true)

        if csv_data.empty?
          return { success: false, error: 'CSV file contains no data rows' }
        end

        @row_count = csv_data.size

        # Validate headers
        header_validation = validate_headers(csv_data.headers)
        return header_validation unless header_validation[:success]

        # Validate each row
        csv_data.each_with_index do |row, index|
          validate_row(row, index + 2) # +2 because CSV is 1-indexed and we skip header
        end

        @valid_rows = @row_count - @errors.count

        {
          success: true,
          total_rows: @row_count,
          valid_rows: @valid_rows,
          invalid_rows: @errors.count,
          errors: @errors,
          warnings: @warnings,
          preview_data: get_preview_data(csv_data)
        }

      rescue CSV::MalformedCSVError => e
        { success: false, error: "Invalid CSV format: #{e.message}" }
      rescue => e
        Rails.logger.error "CSV validation error: #{e.message}"
        { success: false, error: 'Unable to process file. Please check the file format.' }
      end
    end

    private

    def valid_file_extension?
      return false unless @uploaded_file.respond_to?(:original_filename)

      filename = @uploaded_file.original_filename.downcase
      filename.end_with?('.csv')
    end

    def validate_headers(headers)
      expected_headers = get_expected_headers

      if headers.nil? || headers.empty?
        return { success: false, error: 'CSV file must have headers' }
      end

      # Clean headers (remove whitespace, asterisks, convert to lowercase)
      actual_headers = headers.map(&:to_s).map(&:strip).map { |h| h.gsub(/\*/, '') }.map(&:downcase)
      expected_headers_clean = expected_headers.map(&:downcase)

      # Check for required headers
      missing_headers = expected_headers_clean - actual_headers

      if missing_headers.any?
        return {
          success: false,
          error: "Missing required columns: #{missing_headers.join(', ')}"
        }
      end

      # Check for extra headers (just warn, don't fail)
      extra_headers = actual_headers - expected_headers_clean
      if extra_headers.any?
        @warnings << "Extra columns found (will be ignored): #{extra_headers.join(', ')}"
      end

      { success: true }
    end

    def validate_row(row, row_number)
      case @import_type
      when 'customers'
        validate_customer_row(row, row_number)
      when 'delivery_people'
        validate_delivery_person_row(row, row_number)
      when 'products'
        validate_product_row(row, row_number)
      end
    end

    def validate_customer_row(row, row_number)
      errors_for_row = []

      # Required fields validation
      if row['first_name'].blank?
        errors_for_row << "First name is required"
      end

      if row['email'].blank?
        errors_for_row << "Email is required"
      elsif !valid_email?(row['email'])
        errors_for_row << "Invalid email format"
      end

      if row['mobile'].blank?
        errors_for_row << "Mobile number is required"
      elsif !valid_mobile?(row['mobile'])
        errors_for_row << "Invalid mobile number format"
      end

      # Coordinate validation (optional)
      if row['longitude'].present? && !valid_decimal?(row['longitude'])
        errors_for_row << "Invalid longitude format"
      end

      if row['latitude'].present? && !valid_decimal?(row['latitude'])
        errors_for_row << "Invalid latitude format"
      end

      # WhatsApp validation (optional, but should match mobile format if provided)
      if row['whatsapp_number'].present? && !valid_mobile?(row['whatsapp_number'])
        errors_for_row << "Invalid WhatsApp number format"
      end

      if errors_for_row.any?
        @errors << "Row #{row_number}: #{errors_for_row.join(', ')}"
      end
    end

    def validate_delivery_person_row(row, row_number)
      errors_for_row = []

      # Required fields
      ['first_name', 'last_name', 'email', 'mobile'].each do |field|
        if row[field].blank?
          errors_for_row << "#{field} is required"
        end
      end

      # Email validation
      if row['email'].present? && !valid_email?(row['email'])
        errors_for_row << "Invalid email format"
      end

      # Mobile validation
      if row['mobile'].present? && !valid_mobile?(row['mobile'])
        errors_for_row << "Invalid mobile number format"
      end

      # Vehicle type validation
      if row['vehicle_type'].present? && !['bike', 'car', 'van', 'truck'].include?(row['vehicle_type'].downcase)
        errors_for_row << "Vehicle type must be 'bike', 'car', 'van', or 'truck'"
      end

      # Date validation
      if row['joining_date'].present? && !valid_date?(row['joining_date'])
        errors_for_row << "Invalid joining_date format (use YYYY-MM-DD)"
      end

      # Salary validation
      if row['salary'].present? && !valid_decimal?(row['salary'])
        errors_for_row << "Invalid salary amount"
      end

      if errors_for_row.any?
        @errors << "Row #{row_number}: #{errors_for_row.join(', ')}"
      end
    end

    def validate_product_row(row, row_number)
      errors_for_row = []

      # Required fields
      ['name', 'price'].each do |field|
        if row[field].blank?
          errors_for_row << "#{field} is required"
        end
      end

      # Price validation
      if row['price'].present? && !valid_decimal?(row['price'])
        errors_for_row << "Invalid price format"
      end

      # Discount price validation
      if row['discount_price'].present? && !valid_decimal?(row['discount_price'])
        errors_for_row << "Invalid discount_price format"
      end

      # Stock validation
      if row['stock'].present? && !valid_integer?(row['stock'])
        errors_for_row << "Invalid stock quantity"
      end

      # Status validation
      if row['status'].present? && !['active', 'inactive'].include?(row['status'].downcase)
        errors_for_row << "Status must be 'active' or 'inactive'"
      end

      # GST validation
      if row['gst_enabled'].present? && !['true', 'false'].include?(row['gst_enabled'].downcase)
        errors_for_row << "GST enabled must be 'true' or 'false'"
      end

      if row['gst_percentage'].present? && !valid_decimal?(row['gst_percentage'])
        errors_for_row << "Invalid GST percentage"
      end

      # Product type validation
      if row['product_type'].present? && !['one_time', 'subscription'].include?(row['product_type'].downcase)
        errors_for_row << "Product type must be 'one_time' or 'subscription'"
      end

      if errors_for_row.any?
        @errors << "Row #{row_number}: #{errors_for_row.join(', ')}"
      end
    end

    def get_expected_headers
      case @import_type
      when 'customers'
        ['first_name', 'middle_name', 'last_name', 'email', 'mobile',
         'address', 'whatsapp_number', 'longitude', 'latitude']
      when 'delivery_people'
        ['first_name', 'last_name', 'email', 'mobile', 'vehicle_type', 'vehicle_number',
         'license_number', 'address', 'city', 'state', 'pincode',
         'emergency_contact_name', 'emergency_contact_mobile', 'joining_date', 'salary',
         'bank_name', 'account_no', 'ifsc_code', 'account_holder_name', 'delivery_areas']
      when 'products'
        ['name', 'price', 'stock']  # Only the truly required fields
      else
        []
      end
    end

    def get_preview_data(csv_data)
      # Return first 5 rows for preview
      csv_data.first(5).map(&:to_h)
    end

    # Validation helper methods
    def valid_email?(email)
      email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    def valid_mobile?(mobile)
      # Indian mobile number validation (10 digits)
      mobile.gsub(/\D/, '').length == 10
    end

    def valid_date?(date_string)
      Date.parse(date_string.to_s)
      true
    rescue ArgumentError
      false
    end

    def valid_decimal?(value)
      Float(value.to_s)
      true
    rescue ArgumentError
      false
    end

    def valid_integer?(value)
      Integer(value.to_s)
      true
    rescue ArgumentError
      false
    end
  end
end