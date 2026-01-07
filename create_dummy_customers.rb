# Create dummy customers with all fields filled

# Check for existing mobile numbers and delete conflicting records if needed
puts "Checking for existing customers..."
existing_mobiles = ['9876543210', '8765432109', '7654321098', '9123456780', '8234567890', '9345678901']
Customer.where(mobile: existing_mobiles).delete_all

puts "Creating Individual Customers..."

# Individual Customer 1
individual1 = Customer.create!(
  customer_type: 'individual',
  first_name: 'Rajesh',
  middle_name: 'Kumar',
  last_name: 'Sharma',
  email: 'rajesh.sharma@example.com',
  mobile: '9876543210',
  address: '123, MG Road, Koramangala',
  state: 'Karnataka',
  city: 'Bangalore',
  pincode: '560034',
  birth_date: Date.new(1985, 6, 15),
  age: 38,
  gender: 'male',
  height: '5.8',
  height_feet: '5.8',
  weight: '70',
  weight_kg: 70.5,
  education: 'B.Tech Computer Science',
  marital_status: 'married',
  occupation: 'Software Engineer',
  business_job: 'private_job',
  job_name: 'TCS',
  business_name: 'Tata Consultancy Services',
  type_of_duty: 'Software Development',
  annual_income: 1200000,
  pan_number: 'ABCDE1234F',
  pan_no: 'ABCDE1234F',
  gst_number: '29ABCDE1234F1Z5',
  gst_no: '29ABCDE1234F1Z5',
  birth_place: 'Mumbai',
  additional_info: 'Non-smoker, regular health checkups',
  additional_information: 'Prefers online communication',
  nominee_name: 'Priya Sharma',
  nominee_relation: 'spouse',
  nominee_date_of_birth: Date.new(1988, 3, 20),
  sub_agent: 'Self',
  status: true,
  added_by: 'admin'
)

# Individual Customer 2
individual2 = Customer.create!(
  customer_type: 'individual',
  first_name: 'Priya',
  middle_name: 'Devi',
  last_name: 'Patel',
  email: 'priya.patel@example.com',
  mobile: '8765432109',
  address: '456, Ring Road, Satellite',
  state: 'Gujarat',
  city: 'Ahmedabad',
  pincode: '380015',
  birth_date: Date.new(1990, 9, 10),
  age: 33,
  gender: 'female',
  height: '5.4',
  height_feet: '5.4',
  weight: '55',
  weight_kg: 55.0,
  education: 'MBA Finance',
  marital_status: 'single',
  occupation: 'Financial Analyst',
  business_job: 'private_job',
  job_name: 'HDFC Bank',
  business_name: 'HDFC Bank Limited',
  type_of_duty: 'Credit Analysis',
  annual_income: 800000,
  pan_number: 'FGHIJ5678K',
  pan_no: 'FGHIJ5678K',
  gst_number: '24FGHIJ5678K1Z8',
  gst_no: '24FGHIJ5678K1Z8',
  birth_place: 'Surat',
  additional_info: 'Fitness enthusiast, travels frequently',
  additional_information: 'Prefers weekend meetings',
  nominee_name: 'Ramesh Patel',
  nominee_relation: 'father',
  nominee_date_of_birth: Date.new(1960, 12, 5),
  sub_agent: 'Agent_001',
  status: true,
  added_by: 'agent'
)

# Individual Customer 3
individual3 = Customer.create!(
  customer_type: 'individual',
  first_name: 'Amit',
  middle_name: 'Singh',
  last_name: 'Verma',
  email: 'amit.verma@example.com',
  mobile: '7654321098',
  address: '789, CP, Connaught Place',
  state: 'Delhi',
  city: 'Delhi',
  pincode: '110001',
  birth_date: Date.new(1982, 4, 25),
  age: 41,
  gender: 'male',
  height: '6.0',
  height_feet: '6.0',
  weight: '80',
  weight_kg: 80.0,
  education: 'CA',
  marital_status: 'married',
  occupation: 'Chartered Accountant',
  business_job: 'self_employed',
  job_name: 'Verma & Associates',
  business_name: 'Verma & Associates CA Firm',
  type_of_duty: 'Tax Consulting',
  annual_income: 1500000,
  pan_number: 'KLMNO9012P',
  pan_no: 'KLMNO9012P',
  gst_number: '07KLMNO9012P1Z3',
  gst_no: '07KLMNO9012P1Z3',
  birth_place: 'Lucknow',
  additional_info: 'Diabetic, regular medication',
  additional_information: 'Busy during tax season',
  nominee_name: 'Sunita Verma',
  nominee_relation: 'spouse',
  nominee_date_of_birth: Date.new(1985, 8, 14),
  sub_agent: 'Self',
  status: true,
  added_by: 'customer'
)

puts "Created #{Customer.where(customer_type: 'individual').count} individual customers"

puts "\nCreating Corporate Customers..."

# Corporate Customer 1
corporate1 = Customer.create!(
  customer_type: 'corporate',
  company_name: 'Tech Solutions Pvt Ltd',
  email: 'contact@techsolutions.com',
  mobile: '9123456780',
  address: 'Plot 15, Sector 18, Cyber City',
  state: 'Haryana',
  city: 'Gurgaon',
  pincode: '122002',
  annual_income: 5000000,
  pan_number: 'QRSTU3456V',
  pan_no: 'QRSTU3456V',
  gst_number: '06QRSTU3456V1Z9',
  gst_no: '06QRSTU3456V1Z9',
  additional_info: 'IT Services company, 50+ employees',
  additional_information: 'Specializes in web development and mobile apps',
  sub_agent: 'Agent_002',
  status: true,
  added_by: 'agent',
  # Adding contact person details in individual fields
  first_name: 'Vikash',
  middle_name: 'Kumar',
  last_name: 'Agarwal',
  birth_date: Date.new(1980, 11, 8),
  age: 43,
  gender: 'male',
  height: '5.9',
  height_feet: '5.9',
  weight: '75',
  weight_kg: 75.0,
  education: 'B.Tech',
  marital_status: 'married',
  occupation: 'CEO',
  business_job: 'business',
  job_name: 'Chief Executive Officer',
  business_name: 'Tech Solutions Pvt Ltd',
  type_of_duty: 'Management',
  birth_place: 'Kolkata',
  nominee_name: 'Neha Agarwal',
  nominee_relation: 'spouse',
  nominee_date_of_birth: Date.new(1983, 7, 22)
)

# Corporate Customer 2
corporate2 = Customer.create!(
  customer_type: 'corporate',
  company_name: 'Green Energy Solutions Ltd',
  email: 'info@greenenergy.com',
  mobile: '8234567890',
  address: '78, Industrial Area, Phase II',
  state: 'Punjab',
  city: 'Chandigarh',
  pincode: '160002',
  annual_income: 7500000,
  pan_number: 'WXYZB7890C',
  pan_no: 'WXYZB7890C',
  gst_number: '03WXYZB7890C1Z6',
  gst_no: '03WXYZB7890C1Z6',
  additional_info: 'Renewable energy solutions provider',
  additional_information: 'Solar panel installation and maintenance',
  sub_agent: 'Self',
  status: true,
  added_by: 'customer',
  # Adding contact person details
  first_name: 'Meera',
  middle_name: '',
  last_name: 'Krishnan',
  birth_date: Date.new(1987, 2, 14),
  age: 36,
  gender: 'female',
  height: '5.5',
  height_feet: '5.5',
  weight: '60',
  weight_kg: 60.0,
  education: 'M.Tech Environmental Engineering',
  marital_status: 'single',
  occupation: 'Managing Director',
  business_job: 'business',
  job_name: 'Managing Director',
  business_name: 'Green Energy Solutions Ltd',
  type_of_duty: 'Operations Management',
  birth_place: 'Chennai',
  nominee_name: 'Raj Krishnan',
  nominee_relation: 'father',
  nominee_date_of_birth: Date.new(1955, 10, 3)
)

# Corporate Customer 3
corporate3 = Customer.create!(
  customer_type: 'corporate',
  company_name: 'Mumbai Trading Co',
  email: 'admin@mumbaitrading.com',
  mobile: '9345678901',
  address: 'Shop 25, Crawford Market, CST',
  state: 'Maharashtra',
  city: 'Mumbai',
  pincode: '400001',
  annual_income: 3000000,
  pan_number: 'DEFGH2345I',
  pan_no: 'DEFGH2345I',
  gst_number: '27DEFGH2345I1Z2',
  gst_no: '27DEFGH2345I1Z2',
  additional_info: 'Import/Export business, established 1995',
  additional_information: 'Deals in textiles and handicrafts',
  sub_agent: 'Agent_003',
  status: true,
  added_by: 'agent',
  # Adding contact person details
  first_name: 'Ravi',
  middle_name: 'Mohan',
  last_name: 'Shah',
  birth_date: Date.new(1975, 12, 18),
  age: 48,
  gender: 'male',
  height: '5.7',
  height_feet: '5.7',
  weight: '78',
  weight_kg: 78.5,
  education: 'B.Com',
  marital_status: 'married',
  occupation: 'Proprietor',
  business_job: 'business',
  job_name: 'Business Owner',
  business_name: 'Mumbai Trading Co',
  type_of_duty: 'Trading Operations',
  birth_place: 'Mumbai',
  nominee_name: 'Kavita Shah',
  nominee_relation: 'spouse',
  nominee_date_of_birth: Date.new(1978, 5, 30)
)

puts "Created #{Customer.where(customer_type: 'corporate').count} corporate customers"

puts "\nTotal customers created: #{Customer.count}"
puts "Individual customers: #{Customer.where(customer_type: 'individual').count}"
puts "Corporate customers: #{Customer.where(customer_type: 'corporate').count}"

# Display created customers
puts "\n--- INDIVIDUAL CUSTOMERS ---"
Customer.where(customer_type: 'individual').each do |customer|
  puts "#{customer.id}. #{customer.first_name} #{customer.last_name} - #{customer.email} (#{customer.mobile})"
end

puts "\n--- CORPORATE CUSTOMERS ---"
Customer.where(customer_type: 'corporate').each do |customer|
  puts "#{customer.id}. #{customer.company_name} - #{customer.email} (#{customer.mobile})"
  puts "    Contact: #{customer.first_name} #{customer.last_name}"
end

puts "\n✅ Dummy data creation completed!"