require 'csv'
require 'roo'

module ImportService
  class LifeInsuranceImporter
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
      required_headers = %w[customer_email policy_number insurance_company_name]
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

      # Create life insurance policy
      insurance_data[:customer_id] = customer.id
      insurance_data.delete(:customer_email)

      life_insurance = LifeInsurance.new(insurance_data)

      if life_insurance.save
        @imported_count += 1
      else
        @errors << "Row #{row_number}: #{life_insurance.errors.full_messages.join(', ')}"
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
        insured_name: row['insured_name']&.to_s&.strip,
        insurance_company_name: row['insurance_company_name']&.to_s&.strip,
        policy_number: row['policy_number']&.to_s&.strip,
        policy_booking_date: parse_date(row['policy_booking_date']),
        policy_start_date: parse_date(row['policy_start_date']),
        policy_end_date: parse_date(row['policy_end_date']),
        payment_mode: row['payment_mode']&.to_s&.strip,
        sum_insured: parse_number(row['sum_insured']),
        net_premium: parse_number(row['net_premium']),
        first_year_gst_percentage: parse_number(row['first_year_gst_percentage']),
        total_premium: parse_number(row['total_premium']),
        plan_name: row['plan_name']&.to_s&.strip,
        policy_term: parse_number(row['policy_term']),
        premium_payment_term: parse_number(row['premium_payment_term']),
        policy_type: row['policy_type']&.to_s&.strip || 'Individual',
        nominee_name: row['nominee_name']&.to_s&.strip,
        nominee_relationship: row['nominee_relationship']&.to_s&.strip,
        is_admin_added: true,
        is_agent_added: false,
        is_customer_added: false,
        active: true
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

      if insurance_data[:insurance_company_name].blank?
        @errors << "Row #{row_number}: insurance_company_name is required"
        return false
      end

      # Check email format
      if !insurance_data[:customer_email].match?(URI::MailTo::EMAIL_REGEXP)
        @errors << "Row #{row_number}: Invalid email format"
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
      LifeInsurance.exists?(policy_number: insurance_data[:policy_number])
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