require 'csv'
require 'roo'

module ImportService
  class MotorInsuranceImporter
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
      required_headers = %w[customer_email policy_number registration_number]
      missing_headers = required_headers - header.map(&:to_s).map(&:downcase)

      if missing_headers.any?
        raise "Missing required headers: #{missing_headers.join(', ')}"
      end
    end

    def process_row(row, row_number)
      # Clean and normalize data
      insurance_data = normalize_insurance_data(row)

      # Validate row data
      if !valid_row?(insurance_data, row_number)
        @skipped_count += 1
        return
      end

      # Find customer
      customer = find_customer(insurance_data[:customer_email], row_number)
      return unless customer

      # Check for duplicates
      if duplicate_policy?(insurance_data)
        @errors << "Row #{row_number}: Policy with number '#{insurance_data[:policy_number]}' already exists"
        @skipped_count += 1
        return
      end

      # Create motor insurance policy
      insurance_data[:customer_id] = customer.id
      insurance_data.delete(:customer_email)

      motor_insurance = MotorInsurance.new(insurance_data)

      if motor_insurance.save
        @imported_count += 1
      else
        @errors << "Row #{row_number}: #{motor_insurance.errors.full_messages.join(', ')}"
        @skipped_count += 1
      end

    rescue => e
      @errors << "Row #{row_number}: #{e.message}"
      @skipped_count += 1
    end

    def normalize_insurance_data(row)
      {
        customer_email: row['customer_email']&.to_s&.downcase&.strip,
        policy_holder: row['policy_holder']&.to_s&.strip,
        insurance_company_name: row['insurance_company_name']&.to_s&.strip,
        policy_type: row['policy_type']&.to_s&.strip,
        policy_number: row['policy_number']&.to_s&.strip,
        policy_booking_date: parse_date(row['policy_booking_date']),
        policy_start_date: parse_date(row['policy_start_date']),
        policy_end_date: parse_date(row['policy_end_date']),
        registration_number: row['registration_number']&.to_s&.upcase&.strip,
        make: row['make']&.to_s&.strip,
        model: row['model']&.to_s&.strip,
        variant: row['variant']&.to_s&.strip,
        mfy: parse_number(row['mfy'])&.to_i,
        vehicle_type: row['vehicle_type']&.to_s&.strip,
        class_of_vehicle: row['class_of_vehicle']&.to_s&.strip,
        seating_capacity: parse_number(row['seating_capacity'])&.to_i,
        total_idv: parse_number(row['total_idv']),
        net_premium: parse_number(row['net_premium']),
        gst_percentage: parse_number(row['gst_percentage']),
        total_premium: parse_number(row['total_premium']),
        engine_number: row['engine_number']&.to_s&.strip,
        chassis_number: row['chassis_number']&.to_s&.strip,
        insurance_type: row['insurance_type']&.to_s&.strip || 'Comprehensive',
        is_admin_added: true,
        is_agent_added: false,
        is_customer_added: false,
        status: true
      }.compact
    end

    def valid_row?(insurance_data, row_number)
      # Check required fields
      if insurance_data[:customer_email].blank?
        @errors << "Row #{row_number}: customer_email is required"
        return false
      end

      if insurance_data[:policy_number].blank?
        @errors << "Row #{row_number}: policy_number is required"
        return false
      end

      if insurance_data[:registration_number].blank?
        @errors << "Row #{row_number}: registration_number is required"
        return false
      end

      # Check email format
      if !insurance_data[:customer_email].match?(URI::MailTo::EMAIL_REGEXP)
        @errors << "Row #{row_number}: Invalid email format"
        return false
      end

      # Check registration number format (basic validation)
      unless insurance_data[:registration_number].match?(/^[A-Z]{2}\d{2}[A-Z]{1,2}\d{4}$/)
        @errors << "Row #{row_number}: Invalid registration number format"
        return false
      end

      true
    end

    def find_customer(email, row_number)
      customer = Customer.find_by(email: email)
      unless customer
        @errors << "Row #{row_number}: Customer with email '#{email}' not found"
        @skipped_count += 1
        return nil
      end
      customer
    end

    def duplicate_policy?(insurance_data)
      MotorInsurance.exists?(policy_number: insurance_data[:policy_number]) ||
        MotorInsurance.exists?(registration_number: insurance_data[:registration_number])
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
  end
end