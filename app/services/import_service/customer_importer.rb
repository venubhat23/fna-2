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
          row = Hash[[header, spreadsheet.row(i)].transpose]
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
      required_headers = %w[first_name email mobile]
      missing_headers = required_headers - header.map(&:to_s).map(&:downcase)

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
        first_name: row['first_name']&.to_s&.strip,
        middle_name: row['middle_name']&.to_s&.strip,
        last_name: row['last_name']&.to_s&.strip,
        email: row['email']&.to_s&.downcase&.strip,
        mobile: row['mobile']&.to_s&.strip,
        address: row['address']&.to_s&.strip,
        whatsapp_number: row['whatsapp_number']&.to_s&.strip || row['mobile']&.to_s&.strip,
        longitude: parse_decimal(row['longitude']),
        latitude: parse_decimal(row['latitude']),
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

    def generate_password(first_name)
      name_part = first_name.to_s[0..3].upcase.ljust(4, 'X')
      year_part = Date.current.year.to_s
      "#{name_part}@#{year_part}"
    end
  end
end