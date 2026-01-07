module InsuranceCompanyHelper
  # List of insurance companies with their types
  INSURANCE_COMPANIES = {
    "Acko General Insurance Limited" => "GENERAL",
    "Aditya Birla Health Insurance Co Ltd" => "HEALTH",
    "Aditya Birla Health Insurance" => "GENERAL",
    "Agriculture Insurance Company of India Ltd" => "GENERAL",
    "Bajaj Allianz General Insurance Company Limited" => "GENERAL",
    "Care Health Insurance Ltd" => "HEALTH",
    "Care Health Insurance – General" => "GENERAL",
    "Cholamandalam MS General Insurance Co Ltd" => "GENERAL",
    "ECGC Limited" => "GENERAL",
    "Generalli Central Insurance" => "GENERAL",
    "Go Digit General Insurance" => "GENERAL",
    "HDFC ERGO General Insurance Co Ltd" => "GENERAL",
    "ICICI Prudential Life Insurance Co Ltd" => "GENERAL",
    "IFFCO TOKIO General Insurance Co Ltd" => "GENERAL",
    "Kotak Mahindra General Insurance Company Limited" => "GENERAL",
    "Kshema General Insurance Limited" => "GENERAL",
    "Liberty General Insurance Ltd" => "GENERAL",
    "Manipal Cigna Health Insurance Company Limited" => "HEALTH",
    "National Insurance Co Ltd" => "GENERAL",
    "Navi General Insurance Limited" => "GENERAL",
    "Niva Bupa Health Insurance Co Ltd" => "HEALTH",
    "Oriental Insurance Company Limited" => "GENERAL",
    "Raheja QBE General Insurance Co Ltd" => "GENERAL",
    "Reliance General Insurance Co Ltd" => "GENERAL",
    "Royal Sundaram General Insurance Co Ltd" => "GENERAL",
    "Shriram General Insurance Company Limited" => "GENERAL",
    "Star Health Allied Insurance Co Ltd" => "HEALTH",
    "Tata AIG General Insurance Co Ltd" => "GENERAL",
    "The New India Assurance Co Ltd" => "GENERAL",
    "United India Insurance Company Limited" => "GENERAL",
    "Universal Sompo General Insurance Co Ltd" => "GENERAL",
    "Zuno General Insurance Ltd" => "GENERAL"
  }.freeze

  # Get all insurance companies
  def insurance_companies_list
    INSURANCE_COMPANIES.keys
  end

  # Get health insurance companies only
  def health_insurance_companies
    INSURANCE_COMPANIES.select { |name, type| type == "HEALTH" }.keys
  end

  # Get general insurance companies only
  def general_insurance_companies
    INSURANCE_COMPANIES.select { |name, type| type == "GENERAL" }.keys
  end

  # Get options for select dropdown
  def insurance_company_options
    INSURANCE_COMPANIES.map { |name, type| ["#{name} (#{type})", name] }
  end

  # Get health insurance options for select dropdown
  def health_insurance_options
    health_insurance_companies.map { |name| [name, name] }
  end

  # Get general insurance options for select dropdown
  def general_insurance_options
    general_insurance_companies.map { |name| [name, name] }
  end

  # Get company type by name
  def insurance_company_type(name)
    INSURANCE_COMPANIES[name]
  end

  # Check if company is health insurance
  def health_insurance?(name)
    insurance_company_type(name) == "HEALTH"
  end

  # Check if company is general insurance
  def general_insurance?(name)
    insurance_company_type(name) == "GENERAL"
  end
end