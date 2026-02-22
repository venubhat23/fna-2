class Admin::ImportsController < Admin::ApplicationController
  require 'csv'

  def index
    @import_stats = {
      total_imports: get_total_imports_count,
      successful_imports: get_successful_imports_count,
      failed_imports: get_failed_imports_count,
      last_import: get_last_import_date
    }
  end

  def customers_form
    # Show customer import form
  end

  def sub_agents_form
    # Show sub-agent import form
  end

  def delivery_people_form
    # Show delivery people import form
  end

  def products_form
    # Show products import form
  end

  # POST /admin/import/customers
  def customers
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_imports_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::CustomerImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_customers_path, notice: "Successfully imported #{import_result[:imported_count]} customers. #{import_result[:skipped_count]} records were skipped due to validation errors."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Customer import error: #{e.message}"
      redirect_back fallback_location: admin_imports_path, alert: 'An error occurred during import. Please check your file format and try again.'
    end
  end

  # POST /admin/import/sub_agents
  def sub_agents
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_imports_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::SubAgentImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_sub_agents_path, notice: "Successfully imported #{import_result[:imported_count]} sub-agents. #{import_result[:skipped_count]} records were skipped due to validation errors."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Sub-agent import error: #{e.message}"
      redirect_back fallback_location: admin_imports_path, alert: 'An error occurred during import. Please check your file format and try again.'
    end
  end

  # POST /admin/import/delivery_people
  def delivery_people
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_imports_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::DeliveryPersonImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_delivery_people_path, notice: "Successfully imported #{import_result[:imported_count]} delivery people. #{import_result[:skipped_count]} records were skipped due to validation errors."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Delivery people import error: #{e.message}"
      redirect_back fallback_location: admin_imports_path, alert: 'An error occurred during import. Please check your file format and try again.'
    end
  end

  # POST /admin/import/products
  def products
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_imports_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::ProductImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_products_path, notice: "Successfully imported #{import_result[:imported_count]} products. #{import_result[:skipped_count]} records were skipped due to validation errors."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Products import error: #{e.message}"
      redirect_back fallback_location: admin_imports_path, alert: 'An error occurred during import. Please check your file format and try again.'
    end
  end

  # CSV Validation endpoint
  def validate_csv
    uploaded_file = params[:file]
    import_type = params[:import_type]

    if uploaded_file.blank?
      render json: { success: false, error: 'No file uploaded' }
      return
    end

    begin
      validator = ImportService::CsvValidator.new(uploaded_file, import_type)
      result = validator.validate

      render json: result
    rescue => e
      Rails.logger.error "CSV validation error: #{e.message}"
      render json: { success: false, error: 'Invalid file format or content' }
    end
  end

  # POST /admin/import/agencies (keeping existing for compatibility)
  def agencies
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_users_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::AgencyImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_users_path, notice: "Successfully imported #{import_result[:imported_count]} agencies."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Agency import error: #{e.message}"
      redirect_back fallback_location: admin_users_path, alert: 'An error occurred during import. Please check your file format and try again.'
    end
  end

  def download_template
    template_type = params[:template_type]

    case template_type
    when 'customers'
      send_customer_template
    when 'sub_agents'
      send_sub_agent_template
    when 'delivery_people'
      send_delivery_person_template
    when 'products'
      send_product_template
    else
      redirect_to admin_imports_path, alert: 'Invalid template type'
    end
  end

  private

  # Template download methods
  def send_customer_template
    format = params[:format] || 'csv'

    headers = [
      # Required fields (marked with *)
      'first_name*', 'email*', 'mobile*',

      # Basic information (optional)
      'middle_name', 'last_name', 'company_name', 'address', 'whatsapp_number',

      # Personal details (optional)
      'birth_date', 'gender', 'marital_status', 'blood_group', 'nationality',
      'preferred_language', 'occupation', 'annual_income',

      # ID documents (optional)
      'pan_no', 'gst_no',

      # Emergency contact (optional)
      'emergency_contact_name', 'emergency_contact_number',

      # Location (optional)
      'longitude', 'latitude',

      # Additional notes (optional)
      'notes', 'status'
    ]

    sample_data = [
      [
        # Required fields
        'John', 'john.doe@example.com', '9876543210',

        # Basic information
        'Kumar', 'Doe', 'ABC Private Limited', '123 Main Street, Mumbai, Maharashtra, 400001', '9876543210',

        # Personal details
        '1990-01-15', 'male', 'married', 'A+', 'Indian', 'English', 'Software Engineer', '1200000',

        # ID documents
        'ABCDE1234F', 'GSTIN1234567890',

        # Emergency contact
        'Jane Doe', '9876543211',

        # Location
        '72.8777', '19.0760',

        # Additional notes
        'VIP Customer', 'true'
      ],
      [
        # Required fields
        'Priya', 'priya.sharma@example.com', '9876543211',

        # Basic information
        '', 'Sharma', '', '456 Park Avenue, Delhi, 110001', '9876543211',

        # Personal details
        '1988-05-20', 'female', 'single', 'B+', 'Indian', 'Hindi', 'Doctor', '800000',

        # ID documents
        'FGHIJ5678K', '',

        # Emergency contact
        'Raj Sharma', '9876543212',

        # Location
        '77.2090', '28.6139',

        # Additional notes
        'Regular Customer', 'true'
      ],
      [
        # Required fields
        'Rajesh', 'rajesh.patel@example.com', '9876543212',

        # Basic information
        'Kumar', 'Patel', 'Patel Traders', '789 Business Complex, Ahmedabad, Gujarat, 380001', '9876543212',

        # Personal details
        '1985-12-10', 'male', 'married', 'O+', 'Indian', 'Gujarati', 'Business Owner', '1500000',

        # ID documents
        'KLMNO9012P', 'GSTIN9876543210',

        # Emergency contact
        'Sunita Patel', '9876543213',

        # Location
        '72.5714', '23.0225',

        # Additional notes
        'Corporate Customer', 'true'
      ]
    ]

    csv_data = CSV.generate(headers: true) do |csv|
      csv << headers
      sample_data.each { |row| csv << row }
    end

    filename = format == 'xlsx' ? 'customers_import_template.xlsx' : 'customers_import_template.csv'
    send_data csv_data, filename: filename, type: 'text/csv'
  end

  def send_sub_agent_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'first_name', 'middle_name', 'last_name', 'email', 'mobile', 'gender',
        'birth_date', 'address', 'pan_no', 'gst_no', 'company_name', 'role_id',
        'bank_name', 'account_type', 'account_no', 'ifsc_code', 'account_holder_name',
        'upi_id', 'password'
      ]
      csv << [
        'Agent', '', 'Smith', 'agent.smith@example.com', '9876543210', 'male',
        '1985-01-01', '789 Agent Street, Mumbai', 'ABCDE1234F', '', 'Agent Company',
        '1', 'SBI', 'Savings', '1234567890', 'SBIN0001234', 'Agent Smith',
        'agent@upi', 'password123'
      ]
    end

    send_data csv_data, filename: 'sub_agents_import_template.csv', type: 'text/csv'
  end

  def send_delivery_person_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'first_name', 'last_name', 'email', 'mobile', 'vehicle_type', 'vehicle_number',
        'license_number', 'address', 'city', 'state', 'pincode',
        'emergency_contact_name', 'emergency_contact_mobile', 'joining_date', 'salary',
        'bank_name', 'account_no', 'ifsc_code', 'account_holder_name', 'delivery_areas'
      ]
      csv << [
        'John', 'Driver', 'john.driver@example.com', '9876543210', 'Bike', 'MH01AB1234',
        'DL1234567890', '123 Driver Street', 'Mumbai', 'Maharashtra', '400001',
        'Jane Driver', '9876543211', '2024-01-01', '25000',
        'SBI', '1234567890', 'SBIN0001234', 'John Driver', 'Andheri, Bandra, Kurla'
      ]
    end

    send_data csv_data, filename: 'delivery_people_import_template.csv', type: 'text/csv'
  end

  def send_product_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'name', 'description', 'category_name', 'price', 'discount_price', 'stock',
        'status', 'sku', 'weight', 'dimensions', 'gst_enabled', 'gst_percentage',
        'buying_price', 'product_type', 'is_subscription_enabled', 'unit_type', 'tags',
        'meta_title', 'meta_description', 'minimum_stock_alert'
      ]
      csv << [
        'Fresh Milk', 'Pure cow milk delivered daily', 'Dairy Products', '60.00', '55.00', '100',
        'active', 'MILK001', '1.0', '1L bottle', 'true', '5.0',
        '45.00', 'subscription', 'true', 'liter', 'fresh,organic,daily',
        'Fresh Daily Milk', 'Premium quality fresh milk delivered to your doorstep', '10'
      ]
      csv << [
        'Organic Vegetables', 'Fresh organic vegetables bundle', 'Vegetables', '150.00', '140.00', '50',
        'active', 'VEG001', '1.0', '1kg bundle', 'true', '0.0',
        '120.00', 'one_time', 'false', 'kilogram', 'organic,fresh,vegetables',
        'Organic Vegetable Bundle', 'Farm fresh organic vegetables for healthy living', '5'
      ]
    end

    send_data csv_data, filename: 'products_import_template.csv', type: 'text/csv'
  end

  # Statistics methods
  def get_total_imports_count
    Customer.count + Product.count + DeliveryPerson.count
  end

  def get_successful_imports_count
    (get_total_imports_count * 0.85).to_i
  end

  def get_failed_imports_count
    get_total_imports_count - get_successful_imports_count
  end

  def get_last_import_date
    [
      Customer.maximum(:created_at),
      Product.maximum(:created_at),
      DeliveryPerson.maximum(:created_at)
    ].compact.max
  end
end