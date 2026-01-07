require 'csv'
require 'roo'

module ImportService
  class SubAgentImporter
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
      required_headers = %w[first_name last_name email mobile]
      missing_headers = required_headers - header.map(&:to_s).map(&:downcase)

      if missing_headers.any?
        raise "Missing required headers: #{missing_headers.join(', ')}"
      end
    end

    def process_row(row, row_number)
      # Clean and normalize data
      sub_agent_data = normalize_sub_agent_data(row)

      # Validate row data
      if !valid_row?(sub_agent_data, row_number)
        @skipped_count += 1
        return
      end

      # Check for duplicates
      if duplicate_sub_agent?(sub_agent_data)
        @errors << "Row #{row_number}: Sub-agent with email '#{sub_agent_data[:email]}' or mobile '#{sub_agent_data[:mobile]}' already exists"
        @skipped_count += 1
        return
      end

      # Create sub-agent
      sub_agent = SubAgent.new(sub_agent_data)

      if sub_agent.save
        @imported_count += 1
      else
        @errors << "Row #{row_number}: #{sub_agent.errors.full_messages.join(', ')}"
        @skipped_count += 1
      end

    rescue => e
      @errors << "Row #{row_number}: #{e.message}"
      @skipped_count += 1
    end

    def normalize_sub_agent_data(row)
      {
        first_name: row['first_name']&.to_s&.strip,
        middle_name: row['middle_name']&.to_s&.strip,
        last_name: row['last_name']&.to_s&.strip,
        email: row['email']&.to_s&.downcase&.strip,
        mobile: row['mobile']&.to_s&.strip,
        gender: row['gender']&.to_s&.titleize,
        birth_date: parse_date(row['birth_date']),
        address: row['address']&.to_s&.strip,
        pan_no: row['pan_no']&.to_s&.upcase&.strip,
        gst_no: row['gst_no']&.to_s&.upcase&.strip,
        company_name: row['company_name']&.to_s&.strip,
        role_id: parse_role_id(row['role_id']),
        bank_name: row['bank_name']&.to_s&.strip,
        account_type: row['account_type']&.to_s&.titleize,
        account_no: row['account_no']&.to_s&.strip,
        ifsc_code: row['ifsc_code']&.to_s&.upcase&.strip,
        account_holder_name: row['account_holder_name']&.to_s&.strip,
        upi_id: row['upi_id']&.to_s&.strip,
        password: row['password'].present? ? row['password'].to_s : 'password123',
        status: 'active'
      }.compact
    end

    def valid_row?(sub_agent_data, row_number)
      # Check email format
      if sub_agent_data[:email].present? && !sub_agent_data[:email].match?(URI::MailTo::EMAIL_REGEXP)
        @errors << "Row #{row_number}: Invalid email format"
        return false
      end

      # Check mobile format (Indian mobile number)
      if sub_agent_data[:mobile].present?
        clean_mobile = sub_agent_data[:mobile].gsub(/\D/, '')
        unless clean_mobile.match?(/^[6-9]\d{9}$/)
          @errors << "Row #{row_number}: Invalid mobile number format"
          return false
        end
      end

      # Check required fields
      if sub_agent_data[:first_name].blank?
        @errors << "Row #{row_number}: first_name is required"
        return false
      end

      if sub_agent_data[:last_name].blank?
        @errors << "Row #{row_number}: last_name is required"
        return false
      end

      if sub_agent_data[:email].blank?
        @errors << "Row #{row_number}: email is required"
        return false
      end

      if sub_agent_data[:mobile].blank?
        @errors << "Row #{row_number}: mobile is required"
        return false
      end

      # Validate gender if present
      if sub_agent_data[:gender].present? && !%w[Male Female Other].include?(sub_agent_data[:gender])
        @errors << "Row #{row_number}: Invalid gender. Must be 'Male', 'Female', or 'Other'"
        return false
      end

      # Validate account type if present
      if sub_agent_data[:account_type].present? && !%w[Savings Current Salary].include?(sub_agent_data[:account_type])
        @errors << "Row #{row_number}: Invalid account_type. Must be 'Savings', 'Current', or 'Salary'"
        return false
      end

      true
    end

    def duplicate_sub_agent?(sub_agent_data)
      SubAgent.exists?(email: sub_agent_data[:email]) ||
        SubAgent.exists?(mobile: sub_agent_data[:mobile])
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      begin
        Date.parse(date_string.to_s)
      rescue ArgumentError
        nil
      end
    end

    def parse_role_id(role_id_string)
      return 1 if role_id_string.blank? # Default role

      begin
        role_id_string.to_i
      rescue
        1 # Default role
      end
    end
  end
end