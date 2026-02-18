module ImportService
  class DeliveryPersonImporter
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
        validator = CsvValidator.new(@uploaded_file, 'delivery_people')
        validation_result = validator.validate

        unless validation_result[:success]
          return { success: false, error: validation_result[:error] }
        end

        DeliveryPerson.transaction do
          csv_data.each_with_index do |row, index|
            begin
              process_delivery_person_row(row, index + 2)
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
        Rails.logger.error "Delivery person import error: #{e.message}"
        { success: false, error: e.message }
      end
    end

    private

    def process_delivery_person_row(row, row_number)
      # Check if delivery person already exists
      existing_person = DeliveryPerson.find_by(email: row['email'].to_s.strip.downcase)

      if existing_person
        @errors << "Row #{row_number}: Delivery person with email #{row['email']} already exists"
        @skipped_count += 1
        return
      end

      # Create delivery person
      delivery_person_params = {
        first_name: row['first_name'],
        last_name: row['last_name'],
        email: row['email'].to_s.strip.downcase,
        mobile: row['mobile'],
        vehicle_type: row['vehicle_type'],
        vehicle_number: row['vehicle_number'],
        license_number: row['license_number'],
        address: row['address'],
        city: row['city'],
        state: row['state'],
        pincode: row['pincode'],
        emergency_contact_name: row['emergency_contact_name'],
        emergency_contact_mobile: row['emergency_contact_mobile'],
        joining_date: parse_date(row['joining_date']),
        salary: parse_decimal(row['salary']),
        status: true, # Default to active
        bank_name: row['bank_name'],
        account_no: row['account_no'],
        ifsc_code: row['ifsc_code'],
        account_holder_name: row['account_holder_name'],
        delivery_areas: row['delivery_areas']
      }

      # Generate password if not provided
      password = generate_password(row['first_name'], row['last_name'])
      delivery_person_params[:password_digest] = BCrypt::Password.create(password)
      delivery_person_params[:auto_generated_password] = password

      delivery_person = DeliveryPerson.create!(delivery_person_params)

      @imported_count += 1
    end

    def parse_date(date_string)
      return nil if date_string.blank?
      Date.parse(date_string.to_s)
    rescue ArgumentError
      nil
    end

    def parse_decimal(decimal_string)
      return nil if decimal_string.blank?
      BigDecimal(decimal_string.to_s)
    rescue ArgumentError
      nil
    end

    def generate_password(first_name, last_name)
      name_part = first_name.to_s[0..3].upcase.ljust(4, 'X')
      year_part = Date.current.year.to_s
      "#{name_part}@#{year_part}"
    end
  end
end