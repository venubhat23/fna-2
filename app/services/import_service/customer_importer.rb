require 'csv'
require 'roo'
require 'bcrypt'

module ImportService
  class CustomerImporter
    attr_reader :file, :imported_count, :skipped_count, :errors

    def initialize(file)
      @file = file
      @imported_count = 0
      @skipped_count = 0
      @errors = []
    end

    def import
      begin
        spreadsheet = open_spreadsheet(@file)
        header = spreadsheet.row(1)

        validate_headers(header)

        (2..spreadsheet.last_row).each do |i|
          # Clean headers by removing * suffix
          clean_header = header.map { |h| h.to_s.gsub('*', '').strip }
          row = Hash[[clean_header, spreadsheet.row(i)].transpose]
          process_row(row, i)
        end

        {
          success: true,
          imported_count: @imported_count,
          skipped_count: @skipped_count,
          errors: @errors
        }
      rescue => e
        {
          success: false,
          error: e.message,
          imported_count: @imported_count,
          skipped_count: @skipped_count,
          errors: @errors
        }
      end
    end

    private

    def open_spreadsheet(file)
      case File.extname(file.original_filename)
      when '.csv'
        Roo::CSV.new(file.path)
      when '.xls'
        Roo::Excel.new(file.path)
      when '.xlsx'
        Roo::Excelx.new(file.path)
      else
        raise "Unknown file type: #{file.original_filename}"
      end
    end

    def validate_headers(header)
      # Clean headers (remove * suffix and normalize)
      clean_headers = header.map(&:to_s).map { |h| h.gsub('*', '').downcase.strip }

      required_headers = %w[first_name email mobile]
      missing_headers = required_headers - clean_headers

      if missing_headers.any?
        raise "Missing required headers: #{missing_headers.join(', ')}"
      end
    end

    def process_row(row, row_number)
      # Clean and normalize data
      customer_data = normalize_customer_data(row)

      # Validate row data
      if !valid_row?(customer_data, row_number)
        @skipped_count += 1
        return
      end

      # Check for duplicates
      if duplicate_customer?(customer_data)
        @errors << "Row #{row_number}: Customer with email '#{customer_data[:email]}' or mobile '#{customer_data[:mobile]}' already exists"
        @skipped_count += 1
        return
      end

      # Create customer
      customer = Customer.new(customer_data)

      if customer.save
        @imported_count += 1
      else
        @errors << "Row #{row_number}: #{customer.errors.full_messages.join(', ')}"
        @skipped_count += 1
      end

    rescue => e
      @errors << "Row #{row_number}: #{e.message}"
      @skipped_count += 1
    end

    def normalize_customer_data(row)
      # Generate password
      password = generate_password(row['first_name'])

      {
        # Required fields
        first_name: row['first_name']&.to_s&.strip,
        email: row['email']&.to_s&.downcase&.strip,
        mobile: row['mobile']&.to_s&.strip,

        # Basic information
        middle_name: row['middle_name']&.to_s&.strip,
        last_name: row['last_name']&.to_s&.strip,
        company_name: row['company_name']&.to_s&.strip,
        address: row['address']&.to_s&.strip,
        whatsapp_number: row['whatsapp_number']&.to_s&.strip || row['mobile']&.to_s&.strip,

        # Personal details
        birth_date: parse_date(row['birth_date']),
        gender: row['gender']&.to_s&.strip&.downcase,
        marital_status: row['marital_status']&.to_s&.strip&.downcase,
        blood_group: row['blood_group']&.to_s&.strip&.upcase,
        nationality: row['nationality']&.to_s&.strip,
        preferred_language: row['preferred_language']&.to_s&.strip,
        occupation: row['occupation']&.to_s&.strip,
        annual_income: parse_number(row['annual_income']),

        # ID documents
        pan_no: row['pan_no']&.to_s&.strip&.upcase,
        gst_no: row['gst_no']&.to_s&.strip&.upcase,

        # Emergency contact
        emergency_contact_name: row['emergency_contact_name']&.to_s&.strip,
        emergency_contact_number: row['emergency_contact_number']&.to_s&.strip,

        # Location
        longitude: parse_decimal(row['longitude']),
        latitude: parse_decimal(row['latitude']),

        # Additional notes and status
        notes: row['notes']&.to_s&.strip,
        status: parse_boolean(row['status']),

        # Password fields
        password_digest: BCrypt::Password.create(password),
        auto_generated_password: password
      }.compact
    end

    def valid_row?(customer_data, row_number)
      # Check required fields
      if customer_data[:first_name].blank?
        @errors << "Row #{row_number}: first_name is required"
        return false
      end

      if customer_data[:email].blank?
        @errors << "Row #{row_number}: email is required"
        return false
      end

      if customer_data[:mobile].blank?
        @errors << "Row #{row_number}: mobile is required"
        return false
      end

      # Check email format
      if customer_data[:email].present? && !customer_data[:email].match?(URI::MailTo::EMAIL_REGEXP)
        @errors << "Row #{row_number}: Invalid email format"
        return false
      end

      # Check mobile format (Indian mobile number)
      if customer_data[:mobile].present?
        clean_mobile = customer_data[:mobile].gsub(/\D/, '')
        unless clean_mobile.match?(/^[6-9]\d{9}$/)
          @errors << "Row #{row_number}: Invalid mobile number format"
          return false
        end
        # Update mobile to cleaned format
        customer_data[:mobile] = clean_mobile
      end

      # Check PAN format if provided
      if customer_data[:pan_no].present?
        unless customer_data[:pan_no].match?(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/)
          @errors << "Row #{row_number}: Invalid PAN number format (should be ABCDE1234F)"
          return false
        end
      end

      # Check gender values if provided
      if customer_data[:gender].present?
        unless %w[male female other].include?(customer_data[:gender])
          @errors << "Row #{row_number}: Gender must be 'male', 'female', or 'other'"
          return false
        end
      end

      # Check marital status if provided
      if customer_data[:marital_status].present?
        unless %w[single married divorced widowed].include?(customer_data[:marital_status])
          @errors << "Row #{row_number}: Marital status must be 'single', 'married', 'divorced', or 'widowed'"
          return false
        end
      end

      # Check blood group format if provided
      if customer_data[:blood_group].present?
        unless %w[A+ A- B+ B- AB+ AB- O+ O-].include?(customer_data[:blood_group])
          @errors << "Row #{row_number}: Invalid blood group format"
          return false
        end
      end

      true
    end

    def duplicate_customer?(customer_data)
      Customer.exists?(email: customer_data[:email]) ||
        Customer.exists?(mobile: customer_data[:mobile])
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      begin
        Date.parse(date_string.to_s)
      rescue ArgumentError
        nil
      end
    end

    def parse_number(number_string)
      return nil if number_string.blank?

      begin
        number_string.to_s.gsub(/[^\d.]/, '').to_f
      rescue
        nil
      end
    end

    def parse_decimal(decimal_string)
      return nil if decimal_string.blank?
      BigDecimal(decimal_string.to_s)
    rescue ArgumentError
      nil
    end

    def parse_boolean(value)
      return true if value.blank? # Default to true if not specified

      case value.to_s.downcase.strip
      when 'true', '1', 'yes', 'y', 'active'
        true
      when 'false', '0', 'no', 'n', 'inactive'
        false
      else
        true # Default to true for unknown values
      end
    end

    def generate_password(first_name)
      name_part = first_name.to_s[0..3].upcase.ljust(4, 'X')
      year_part = Date.current.year.to_s
      "#{name_part}@#{year_part}"
    end
  end
end