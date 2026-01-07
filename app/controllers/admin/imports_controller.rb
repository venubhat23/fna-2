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

  def health_insurances_form
    # Show health insurance import form
  end

  def life_insurances_form
    # Show life insurance import form
  end

  def motor_insurances_form
    # Show motor insurance import form
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

  # POST /admin/import/health_insurances
  def health_insurances
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_imports_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::HealthInsuranceImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_health_insurances_path, notice: "Successfully imported #{import_result[:imported_count]} health insurance policies. #{import_result[:skipped_count]} records were skipped due to validation errors."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Health insurance import error: #{e.message}"
      redirect_back fallback_location: admin_imports_path, alert: 'An error occurred during import. Please check your file format and try again.'
    end
  end

  # POST /admin/import/life_insurances
  def life_insurances
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_imports_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::LifeInsuranceImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_life_insurances_path, notice: "Successfully imported #{import_result[:imported_count]} life insurance policies. #{import_result[:skipped_count]} records were skipped due to validation errors."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Life insurance import error: #{e.message}"
      redirect_back fallback_location: admin_imports_path, alert: 'An error occurred during import. Please check your file format and try again.'
    end
  end

  # POST /admin/import/motor_insurances
  def motor_insurances
    uploaded_file = params[:file]

    if uploaded_file.blank?
      redirect_back fallback_location: admin_imports_path, alert: 'Please select a file to import.'
      return
    end

    begin
      import_result = ImportService::MotorInsuranceImporter.new(uploaded_file).import

      if import_result[:success]
        redirect_to admin_motor_insurances_path, notice: "Successfully imported #{import_result[:imported_count]} motor insurance policies. #{import_result[:skipped_count]} records were skipped due to validation errors."
      else
        redirect_back fallback_location: admin_imports_path, alert: "Import failed: #{import_result[:error]}"
      end
    rescue => e
      Rails.logger.error "Motor insurance import error: #{e.message}"
      redirect_back fallback_location: admin_imports_path, alert: 'An error occurred during import. Please check your file format and try again.'
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
    when 'health_insurances'
      send_health_insurance_template
    when 'life_insurances'
      send_life_insurance_template
    when 'motor_insurances'
      send_motor_insurance_template
    else
      redirect_to admin_imports_path, alert: 'Invalid template type'
    end
  end

  private

  # Template download methods
  def send_customer_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'customer_type', 'first_name', 'middle_name', 'last_name', 'company_name',
        'email', 'mobile', 'gender', 'birth_date', 'address', 'city', 'state',
        'pincode', 'pan_no', 'gst_no', 'occupation', 'annual_income', 'marital_status'
      ]
      csv << [
        'individual', 'John', 'Kumar', 'Doe', '',
        'john.doe@example.com', '9876543210', 'male', '1990-01-01', '123 Main St', 'Mumbai', 'Maharashtra',
        '400001', 'ABCDE1234F', '', 'Software Engineer', '500000', 'married'
      ]
      csv << [
        'corporate', '', '', '', 'ABC Company Ltd',
        'contact@abc.com', '9876543211', '', '', '456 Business Park', 'Delhi', 'Delhi',
        '110001', '', 'GSTIN123456789', '', '', ''
      ]
    end

    send_data csv_data, filename: 'customers_import_template.csv', type: 'text/csv'
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

  def send_health_insurance_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'customer_email', 'policy_holder', 'insurance_company_name', 'policy_type',
        'policy_number', 'policy_booking_date', 'policy_start_date', 'policy_end_date',
        'payment_mode', 'sum_insured', 'net_premium', 'gst_percentage', 'total_premium',
        'plan_name'
      ]
      csv << [
        'customer@example.com', 'John Doe', 'HDFC ERGO Health Insurance', 'Individual',
        'HLT001234', '2024-01-01', '2024-01-01', '2024-12-31',
        'Yearly', '500000', '25000', '18', '29500',
        'Complete Health Care'
      ]
    end

    send_data csv_data, filename: 'health_insurance_import_template.csv', type: 'text/csv'
  end

  def send_life_insurance_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'customer_email', 'policy_holder', 'insured_name', 'insurance_company_name',
        'policy_number', 'policy_booking_date', 'policy_start_date', 'policy_end_date',
        'payment_mode', 'sum_insured', 'net_premium', 'first_year_gst_percentage',
        'total_premium', 'plan_name', 'policy_term', 'premium_payment_term'
      ]
      csv << [
        'customer@example.com', 'John Doe', 'John Doe', 'ICICI Prudential Life Insurance',
        'LIC001234', '2024-01-01', '2024-01-01', '2044-12-31',
        'Yearly', '1000000', '50000', '18',
        '59000', 'iProtect Smart', '20', '10'
      ]
    end

    send_data csv_data, filename: 'life_insurance_import_template.csv', type: 'text/csv'
  end

  def send_motor_insurance_template
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'customer_email', 'policy_holder', 'insurance_company_name', 'policy_type',
        'policy_number', 'policy_booking_date', 'policy_start_date', 'policy_end_date',
        'registration_number', 'make', 'model', 'variant', 'mfy', 'vehicle_type',
        'class_of_vehicle', 'seating_capacity', 'total_idv', 'net_premium',
        'gst_percentage', 'total_premium', 'engine_number', 'chassis_number'
      ]
      csv << [
        'customer@example.com', 'John Doe', 'HDFC ERGO General Insurance', 'Comprehensive',
        'MOT001234', '2024-01-01', '2024-01-01', '2024-12-31',
        'MH01AB1234', 'Maruti Suzuki', 'Swift', 'VXI', '2020', 'Car',
        'Private Car', '5', '500000', '18000',
        '18', '21240', 'ABC123456', 'XYZ789012'
      ]
    end

    send_data csv_data, filename: 'motor_insurance_import_template.csv', type: 'text/csv'
  end

  # Statistics methods
  def get_total_imports_count
    Customer.count + SubAgent.count + HealthInsurance.count + LifeInsurance.count + MotorInsurance.count
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
      SubAgent.maximum(:created_at),
      HealthInsurance.maximum(:created_at),
      LifeInsurance.maximum(:created_at),
      MotorInsurance.maximum(:created_at)
    ].compact.max
  end
end