# Drwise Mobile API - Request/Response Examples

This document provides detailed request and response examples for all Drwise Mobile API endpoints with various scenarios including success cases, error cases, and edge cases.

## Table of Contents
1. [Authentication Examples](#authentication-examples)
2. [Dashboard Examples](#dashboard-examples)
3. [Customer Management Examples](#customer-management-examples)
4. [Policy Management Examples](#policy-management-examples)
5. [Leads Management Examples](#leads-management-examples)
6. [Insurance Companies Examples](#insurance-companies-examples)
7. [Form Data Examples](#form-data-examples)
8. [Error Response Examples](#error-response-examples)

## Authentication Examples

### Agent Login

#### Success Case
**Request:**
```http
POST /api/v1/mobile/auth/login
Content-Type: application/json

{
  "email": "subagent@drwise.com",
  "password": "subagent123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyLCJyb2xlIjoiYWdlbnQiLCJleHAiOjE3MzQ0MDc4NTZ9.abc123def456",
    "user": {
      "id": 2,
      "name": "Rajesh Kumar",
      "email": "subagent@drwise.com",
      "mobile": "9876543210",
      "user_type": "agent",
      "role": "agent_role"
    }
  }
}
```

#### Invalid Credentials
**Request:**
```http
POST /api/v1/mobile/auth/login
Content-Type: application/json

{
  "email": "wrong@email.com",
  "password": "wrongpassword"
}
```

**Response (401):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

## Dashboard Examples

### Get Dashboard Statistics

#### Success Case
**Request:**
```http
GET /api/v1/mobile/agent/dashboard
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "agent_info": {
      "name": "Rajesh Kumar",
      "email": "subagent@drwise.com",
      "mobile": "9876543210",
      "role": "agent_role"
    },
    "statistics": {
      "customers_count": 25,
      "policies_count": 45,
      "health_policies_count": 28,
      "life_policies_count": 17,
      "total_premium": 2500000,
      "commission_earned": 125000,
      "this_month_policies": 8,
      "this_month_premium": 450000
    },
    "recent_activities": [
      {
        "type": "policy_created",
        "message": "Health insurance policy HLT001 created for John Doe",
        "timestamp": "2024-12-15T10:30:00Z",
        "policy_type": "Health"
      },
      {
        "type": "policy_created",
        "message": "Life insurance policy LIC001 created for Jane Smith",
        "timestamp": "2024-12-14T15:45:00Z",
        "policy_type": "Life"
      }
    ]
  }
}
```

## Customer Management Examples

### Get Customers List

#### All Customers
**Request:**
```http
GET /api/v1/mobile/agent/customers?page=1&per_page=5&filter=all
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": 5,
        "name": "Priya Sharma",
        "mobile": "9876543211",
        "email": "priya@example.com",
        "password": "priya3211123",
        "customer_type": "individual",
        "status": "Active",
        "policies_count": 3,
        "total_premium": 85000,
        "added_by": "agent_mobile_api_2",
        "added_via": "mobile_api",
        "created_at": "2024-12-15T08:30:00Z"
      },
      {
        "id": 8,
        "name": "Amit Patel",
        "mobile": "9876543212",
        "email": "amit@example.com",
        "password": "amit3212123",
        "customer_type": "individual",
        "status": "Active",
        "policies_count": 1,
        "total_premium": 25000,
        "added_by": "system_admin",
        "added_via": "system",
        "created_at": "2024-12-10T14:20:00Z"
      }
    ],
    "statistics": {
      "total_customers": 25,
      "agent_added_customers": 12,
      "system_added_customers": 13,
      "my_added_customers": 8
    },
    "pagination": {
      "current_page": 1,
      "per_page": 5,
      "total_customers": 25,
      "total_pages": 5
    }
  }
}
```

#### Agent Added Customers Only
**Request:**
```http
GET /api/v1/mobile/agent/customers?filter=agent_added&page=1&per_page=10
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": 5,
        "name": "Priya Sharma",
        "mobile": "9876543211",
        "email": "priya@example.com",
        "password": "priya3211123",
        "customer_type": "individual",
        "status": "Active",
        "policies_count": 3,
        "total_premium": 85000,
        "added_by": "agent_mobile_api_2",
        "added_via": "mobile_api",
        "created_at": "2024-12-15T08:30:00Z"
      }
    ],
    "statistics": {
      "total_customers": 12,
      "agent_added_customers": 12,
      "system_added_customers": 0,
      "my_added_customers": 8
    },
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_customers": 12,
      "total_pages": 2
    }
  }
}
```

### Add Customer

#### Success Case - Individual Customer
**Request:**
```http
POST /api/v1/mobile/agent/customers
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "customer_type": "individual",
  "first_name": "Amit",
  "last_name": "Patel",
  "email": "amit.patel@email.com",
  "mobile": "9876543210",
  "gender": "Male",
  "birth_date": "1990-05-15",
  "address": "123 Main Street, Sector 15",
  "city": "Bangalore",
  "state": "Karnataka",
  "pincode": "560001",
  "pan_no": "ABCDE1234F",
  "occupation": "Software Engineer",
  "annual_income": 1200000,
  "marital_status": "Married",
  "file1": "data:application/pdf;base64,JVBERi0xLjQKJdPr6eEK...",
  "file2": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEA..."
}
```

**Response (201):**
```json
{
  "status": true,
  "message": "Customer created successfully",
  "data": {
    "customer_id": 26,
    "name": "Amit Patel",
    "email": "amit.patel@email.com",
    "mobile": "9876543210",
    "image_url": "",
    "customer_type": "individual",
    "gender": "Male",
    "birth_date": "1990-05-15",
    "address": "123 Main Street, Sector 15",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560001",
    "pan_no": "ABCDE1234F",
    "occupation": "Software Engineer",
    "annual_income": 1200000,
    "marital_status": "Married",
    "files": {
      "file1": {
        "filename": "customer_26_file1_1734321456.pdf",
        "content_type": "application/pdf",
        "file_size": 15420,
        "uploaded_at": "2024-12-16 10:30:56",
        "type": "file1"
      },
      "file2": {
        "filename": "customer_26_file2_1734321456.jpg",
        "content_type": "image/jpeg",
        "file_size": 8750,
        "uploaded_at": "2024-12-16 10:30:56",
        "type": "file2"
      },
      "upload_status": "success",
      "upload_errors": []
    },
    "added_by": "agent_mobile_api_2",
    "added_by_agent": {
      "id": 2,
      "name": "Rajesh Kumar",
      "email": "subagent@insurebook.com"
    },
    "created_at": "2024-12-16 10:30:56"
  }
}
```

#### Success Case - Corporate Customer
**Request:**
```http
POST /api/v1/mobile/agent/customers
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "customer_type": "corporate",
  "first_name": "Rajesh",
  "last_name": "Kumar",
  "company_name": "Tech Solutions Pvt Ltd",
  "email": "rajesh@techsolutions.com",
  "mobile": "9876543220",
  "address": "Tech Park, Whitefield",
  "city": "Bangalore",
  "state": "Karnataka",
  "pincode": "560066",
  "pan_no": "ABCDE5678G",
  "gst_no": "29ABCDE5678G1Z5",
  "occupation": "Business Owner",
  "annual_income": 5000000
}
```

**Response (201):**
```json
{
  "status": true,
  "message": "Customer created successfully",
  "data": {
    "customer_id": 27,
    "name": "Rajesh Kumar",
    "email": "rajesh@techsolutions.com",
    "mobile": "9876543220",
    "customer_type": "corporate",
    "company_name": "Tech Solutions Pvt Ltd",
    "address": "Tech Park, Whitefield",
    "city": "Bangalore",
    "state": "Karnataka",
    "pincode": "560066",
    "pan_no": "ABCDE5678G",
    "gst_no": "29ABCDE5678G1Z5",
    "occupation": "Business Owner",
    "annual_income": 5000000,
    "files": {
      "file1": null,
      "file2": null,
      "upload_status": "success",
      "upload_errors": []
    },
    "added_by": "agent_mobile_api_2",
    "added_by_agent": {
      "id": 2,
      "name": "Rajesh Kumar",
      "email": "subagent@insurebook.com"
    },
    "created_at": "2024-12-16 10:45:30"
  }
}
```

#### Validation Error Case
**Request:**
```http
POST /api/v1/mobile/agent/customers
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "customer_type": "individual",
  "first_name": "",
  "email": "invalid-email",
  "mobile": "123456789"
}
```

**Response (422):**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": [
    "First name is required",
    "Invalid email format",
    "Invalid phone number format. Must be a valid Indian mobile number"
  ]
}
```

#### Duplicate Customer Error
**Request:**
```http
POST /api/v1/mobile/agent/customers
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "customer_type": "individual",
  "first_name": "Existing",
  "last_name": "Customer",
  "email": "existing@example.com",
  "mobile": "9876543211"
}
```

**Response (422):**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": [
    "Customer with this email already exists",
    "Customer with this mobile number already exists"
  ]
}
```

## Policy Management Examples

### Get Policies List

#### All Policies
**Request:**
```http
GET /api/v1/mobile/agent/policies?page=1&per_page=5&policy_type=all
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "policies": [
      {
        "id": 15,
        "insurance_name": "Star Family Health Plan",
        "insurance_type": "Health",
        "policy_number": "SH2024001",
        "client_name": "Priya Sharma",
        "policy_type": "New",
        "policy_holder": "Self",
        "entry_date": "2024-12-15",
        "start_date": "2024-12-16",
        "end_date": "2025-12-16",
        "total_premium": 45000,
        "sum_insured": 500000,
        "insurance_company": "Star Health Insurance",
        "payment_mode": "yearly",
        "commission_amount": 2250,
        "status": "Active"
      },
      {
        "id": 8,
        "insurance_name": "LIC Jeevan Anand",
        "insurance_type": "Life",
        "policy_number": "LIC2024001",
        "client_name": "Amit Patel",
        "policy_type": "New",
        "policy_holder": "Amit Patel",
        "entry_date": "2024-12-14",
        "start_date": "2024-12-16",
        "end_date": "2044-12-16",
        "total_premium": 59000,
        "sum_insured": 1000000,
        "insurance_company": "LIC of India",
        "payment_mode": "yearly",
        "commission_amount": 2950,
        "status": "Active"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 5,
      "total_policies": 45,
      "total_pages": 9
    }
  }
}
```

#### Health Policies Only
**Request:**
```http
GET /api/v1/mobile/agent/policies?policy_type=health&page=1&per_page=10
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "policies": [
      {
        "id": 15,
        "insurance_name": "Star Family Health Plan",
        "insurance_type": "Health",
        "policy_number": "SH2024001",
        "client_name": "Priya Sharma",
        "policy_type": "New",
        "policy_holder": "Self",
        "entry_date": "2024-12-15",
        "start_date": "2024-12-16",
        "end_date": "2025-12-16",
        "total_premium": 45000,
        "sum_insured": 500000,
        "insurance_company": "Star Health Insurance",
        "payment_mode": "yearly",
        "commission_amount": 2250,
        "status": "Active"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_policies": 28,
      "total_pages": 3
    }
  }
}
```

### Add Health Insurance Policy

#### Success Case with Family Members and Documents
**Request:**
```http
POST /api/v1/mobile/agent/policies/health
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "client_id": 5,
  "policy_holder": "Self",
  "insurance_company_id": 5,
  "policy_type": "individual",
  "insurance_type": "health",
  "plan_name": "Star Family Health Plan",
  "policy_number": "SH2024001",
  "policy_booking_date": "2024-12-15",
  "policy_start_date": "2024-12-16",
  "policy_end_date": "2025-12-16",
  "policy_term_years": 1,
  "payment_mode": "yearly",
  "sum_insured": 500000,
  "net_premium": 38136,
  "gst_percentage": 18,
  "total_premium": 45000,
  "installment_autopay_start_date": "2024-12-16",
  "installment_autopay_end_date": "2025-12-16",
  "family_members": [
    {
      "full_name": "Raj Sharma",
      "age": 35,
      "relationship": "spouse",
      "sum_insured": 250000
    },
    {
      "full_name": "Aadhya Sharma",
      "age": 8,
      "relationship": "child",
      "sum_insured": 250000
    }
  ],
  "documents": [
    {
      "document_type": "policy_copy",
      "document_file": "JVBERi0xLjQKJdPr6eEKMSAwIG9iago8..."
    },
    {
      "document_type": "id_proof",
      "document_file": "JVBERi0xLjQKJdPr6eEKMSAwIG9iago8..."
    }
  ]
}
```

**Response (201):**
```json
{
  "status": true,
  "message": "Health policy created successfully",
  "data": {
    "policy_id": 15,
    "policy_number": "SH2024001",
    "client_name": "Priya Sharma",
    "total_premium": 45000,
    "created_at": "2024-12-16 10:45:30"
  }
}
```

#### Missing Required Fields Error
**Request:**
```http
POST /api/v1/mobile/agent/policies/health
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "client_id": "",
  "policy_holder": "",
  "plan_name": ""
}
```

**Response (422):**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": [
    "Client ID is required",
    "Policy holder is required",
    "Insurance company ID is required",
    "Plan name is required",
    "Policy number is required",
    "Net premium is required"
  ]
}
```

#### Customer Not Found Error
**Request:**
```http
POST /api/v1/mobile/agent/policies/health
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "client_id": 9999,
  "policy_holder": "Self",
  "insurance_company_id": 5,
  "plan_name": "Star Health Plan",
  "policy_number": "SH2024999",
  "net_premium": 25000
}
```

**Response (404):**
```json
{
  "status": false,
  "message": "Customer not found"
}
```

#### Duplicate Policy Number Error
**Request:**
```http
POST /api/v1/mobile/agent/policies/health
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "client_id": 5,
  "policy_holder": "Self",
  "insurance_company_id": 5,
  "plan_name": "Star Health Plan",
  "policy_number": "SH2024001",
  "net_premium": 25000
}
```

**Response (422):**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": {
    "policy_number": ["has already been taken"]
  }
}
```

### Add Life Insurance Policy

#### Success Case
**Request:**
```http
POST /api/v1/mobile/agent/policies/life
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "customer_id": 5,
  "policy_holder": "Priya Sharma",
  "plan_name": "LIC Jeevan Anand",
  "policy_number": "LIC2024001",
  "insurance_company_name": "LIC of India",
  "policy_type": "New",
  "policy_start_date": "2024-12-16",
  "policy_end_date": "2044-12-16",
  "payment_mode": "yearly",
  "policy_term": 20,
  "premium_payment_term": 15,
  "sum_insured": 1000000,
  "net_premium": 50000,
  "total_premium": 59000,
  "nominee_name": "Raj Sharma",
  "nominee_relationship": "Spouse",
  "agent_commission_percentage": 5,
  "commission_amount": 2950
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Life insurance policy added successfully",
  "data": {
    "id": 8,
    "insurance_name": "LIC Jeevan Anand",
    "insurance_type": "Life",
    "policy_number": "LIC2024001",
    "client_name": "Priya Sharma",
    "policy_type": "New",
    "policy_holder": "Priya Sharma",
    "entry_date": "2024-12-16",
    "start_date": "2024-12-16",
    "end_date": "2044-12-16",
    "total_premium": 59000,
    "sum_insured": 1000000,
    "insurance_company": "LIC of India",
    "payment_mode": "yearly",
    "commission_amount": 2950,
    "status": "Active"
  }
}
```

### Add Motor Insurance Policy

#### Success Case
**Request:**
```http
POST /api/v1/mobile/agent/policies/motor
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "customer_id": 5,
  "policy_holder": "Priya Sharma",
  "plan_name": "Comprehensive Motor Plan",
  "policy_number": "MTR2024001",
  "insurance_company_name": "Bajaj Allianz General Insurance",
  "policy_type": "New",
  "policy_start_date": "2024-12-16",
  "policy_end_date": "2025-12-16",
  "payment_mode": "yearly",
  "sum_insured": 800000,
  "net_premium": 15000,
  "gst_percentage": 18,
  "total_premium": 17700,
  "agent_commission_percentage": 10,
  "commission_amount": 1770,
  "vehicle_make": "Maruti Suzuki",
  "vehicle_model": "Swift",
  "vehicle_number": "KA01AB1234",
  "vehicle_year": "2022",
  "engine_number": "ABC123456",
  "chassis_number": "DEF789012",
  "vehicle_type": "Four Wheeler"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Motor insurance policy added successfully",
  "data": {
    "id": 12,
    "insurance_name": "Comprehensive Motor Plan",
    "insurance_type": "Motor",
    "policy_number": "MTR2024001",
    "client_name": "Priya Sharma",
    "policy_type": "New",
    "policy_holder": "Priya Sharma",
    "entry_date": "2024-12-16",
    "start_date": "2024-12-16",
    "end_date": "2025-12-16",
    "total_premium": 17700,
    "sum_insured": 800000,
    "insurance_company": "Bajaj Allianz General Insurance",
    "payment_mode": "yearly",
    "commission_amount": 1770,
    "status": "Active"
  }
}
```

### Add Other Insurance Policy

#### Success Case
**Request:**
```http
POST /api/v1/mobile/agent/policies/other
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "customer_id": 5,
  "policy_holder": "Priya Sharma",
  "plan_name": "Home Insurance Plan",
  "policy_number": "HOME2024001",
  "insurance_company_name": "HDFC ERGO General Insurance",
  "policy_type": "New",
  "policy_start_date": "2024-12-16",
  "policy_end_date": "2025-12-16",
  "payment_mode": "yearly",
  "sum_insured": 5000000,
  "net_premium": 8000,
  "gst_percentage": 18,
  "total_premium": 9440,
  "agent_commission_percentage": 8,
  "commission_amount": 755,
  "coverage_type": "Property",
  "description": "Comprehensive home insurance covering structure and contents"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Other insurance policy added successfully",
  "data": {
    "id": 18,
    "insurance_name": "Home Insurance Plan",
    "insurance_type": "Other",
    "policy_number": "HOME2024001",
    "client_name": "Priya Sharma",
    "policy_type": "New",
    "policy_holder": "Priya Sharma",
    "entry_date": "2024-12-16",
    "start_date": "2024-12-16",
    "end_date": "2025-12-16",
    "total_premium": 9440,
    "sum_insured": 5000000,
    "insurance_company": "HDFC ERGO General Insurance",
    "payment_mode": "yearly",
    "commission_amount": 755,
    "status": "Active"
  }
}
```

## Leads Management Examples

### Get Leads List

#### All Leads
**Request:**
```http
GET /api/v1/mobile/agent/leads?page=1&per_page=5
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "leads": [
      {
        "id": 5,
        "lead_id": "LD240001",
        "name": "Suresh Kumar",
        "contact_number": "9876543215",
        "email": "suresh@example.com",
        "product_interest": "Health",
        "current_stage": "Consultation",
        "priority": "High",
        "lead_source": "Agent referral",
        "created_date": "2024-12-15",
        "full_address": "Mumbai, Maharashtra",
        "referred_by": "Existing Customer",
        "stage_progress": 20,
        "stage_description": "Initial consultation scheduled",
        "can_advance": true,
        "can_go_back": false,
        "next_stage": "One-on-One",
        "previous_stage": null,
        "converted_customer_id": null,
        "created_policy_id": null,
        "referral_amount": 0.0,
        "transferred_amount": false,
        "stage_badge_class": "badge-primary",
        "source_badge_class": "badge-info",
        "product_badge_class": "badge-success",
        "created_at": "2024-12-15 14:30:25"
      },
      {
        "id": 8,
        "lead_id": "LD240002",
        "name": "Meera Gupta",
        "contact_number": "9876543216",
        "email": "meera@example.com",
        "product_interest": "Life",
        "current_stage": "One-on-One",
        "priority": "Medium",
        "lead_source": "Online",
        "created_date": "2024-12-14",
        "full_address": "Delhi, Delhi",
        "referred_by": "Website",
        "stage_progress": 40,
        "stage_description": "One-on-one meeting scheduled",
        "can_advance": true,
        "can_go_back": true,
        "next_stage": "Converted",
        "previous_stage": "Consultation",
        "converted_customer_id": null,
        "created_policy_id": null,
        "referral_amount": 500.0,
        "transferred_amount": false,
        "stage_badge_class": "badge-warning",
        "source_badge_class": "badge-success",
        "product_badge_class": "badge-info",
        "created_at": "2024-12-14 11:15:40"
      }
    ],
    "statistics": {
      "total_leads": 15,
      "this_month_leads": 8,
      "pending_leads": 12,
      "converted_leads": 3,
      "conversion_rate": 20.0,
      "by_stage": {
        "consultation": 8,
        "one_on_one": 4,
        "converted": 2,
        "policy_created": 1,
        "referral_settled": 0
      },
      "by_product": {
        "health": 8,
        "life": 4,
        "motor": 2,
        "home": 1,
        "travel": 0,
        "other": 0
      },
      "by_source": {
        "online": 3,
        "offline": 2,
        "agent_referral": 8,
        "walk_in": 2,
        "tele_calling": 0,
        "campaign": 0
      }
    },
    "pagination": {
      "current_page": 1,
      "per_page": 5,
      "total_leads": 15,
      "total_pages": 3
    }
  }
}
```

#### Filtered Leads by Stage and Product
**Request:**
```http
GET /api/v1/mobile/agent/leads?stage=consultation&product=health&page=1&per_page=10
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "leads": [
      {
        "id": 5,
        "lead_id": "LD240001",
        "name": "Suresh Kumar",
        "contact_number": "9876543215",
        "email": "suresh@example.com",
        "product_interest": "Health",
        "current_stage": "Consultation",
        "priority": "High",
        "lead_source": "Agent referral",
        "created_date": "2024-12-15",
        "full_address": "Mumbai, Maharashtra",
        "referred_by": "Existing Customer",
        "stage_progress": 20,
        "stage_description": "Initial consultation scheduled",
        "can_advance": true,
        "can_go_back": false,
        "next_stage": "One-on-One",
        "previous_stage": null,
        "converted_customer_id": null,
        "created_policy_id": null,
        "referral_amount": 0.0,
        "transferred_amount": false,
        "stage_badge_class": "badge-primary",
        "source_badge_class": "badge-info",
        "product_badge_class": "badge-success",
        "created_at": "2024-12-15 14:30:25"
      }
    ],
    "statistics": {
      "total_leads": 5,
      "this_month_leads": 3,
      "pending_leads": 5,
      "converted_leads": 0,
      "conversion_rate": 0.0,
      "by_stage": {
        "consultation": 5,
        "one_on_one": 0,
        "converted": 0,
        "policy_created": 0,
        "referral_settled": 0
      },
      "by_product": {
        "health": 5,
        "life": 0,
        "motor": 0,
        "home": 0,
        "travel": 0,
        "other": 0
      },
      "by_source": {
        "online": 1,
        "offline": 1,
        "agent_referral": 3,
        "walk_in": 0,
        "tele_calling": 0,
        "campaign": 0
      }
    },
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_leads": 5,
      "total_pages": 1
    }
  }
}
```

### Add Lead

#### Success Case
**Request:**
```http
POST /api/v1/mobile/agent/leads
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "name": "Suresh Kumar",
  "contact_number": "9876543215",
  "email": "suresh@example.com",
  "product_interest": "health",
  "address": "Flat 202, Rose Apartments",
  "city": "Mumbai",
  "state": "Maharashtra",
  "referred_by": "Existing Customer",
  "current_stage": "consultation",
  "created_date": "2024-12-15",
  "priority": "high",
  "note": "Interested in family health insurance",
  "call_disposition": "Positive response",
  "lead_source": "agent_referral",
  "referral_amount": 0.0,
  "transferred_amount": false
}
```

**Response (201):**
```json
{
  "status": true,
  "message": "Lead created successfully",
  "data": {
    "lead_id": "LD240001",
    "id": 5,
    "name": "Suresh Kumar",
    "contact_number": "9876543215",
    "email": "suresh@example.com",
    "product_interest": "health",
    "current_stage": "consultation",
    "priority": "high",
    "lead_source": "agent_referral",
    "created_at": "2024-12-15 14:30:25",
    "stage_progress": 20,
    "can_advance": true,
    "next_stage": "one_on_one"
  }
}
```

#### Validation Error Case
**Request:**
```http
POST /api/v1/mobile/agent/leads
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "name": "",
  "contact_number": "123456789",
  "email": "invalid-email",
  "product_interest": "invalid_product"
}
```

**Response (422):**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": [
    "Name is required",
    "Invalid phone number format. Must be a valid Indian mobile number",
    "Invalid email format",
    "Invalid product interest"
  ]
}
```

#### Duplicate Contact Number Error
**Request:**
```http
POST /api/v1/mobile/agent/leads
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "name": "Duplicate Lead",
  "contact_number": "9876543215",
  "product_interest": "health"
}
```

**Response (422):**
```json
{
  "status": false,
  "message": "Validation failed",
  "errors": {
    "contact_number": ["A lead with this contact number already exists"]
  }
}
```

## Insurance Companies Examples

### Get Insurance Companies

#### All Companies
**Request:**
```http
GET /api/v1/mobile/agent/insurance_companies?page=1&per_page=5&status=all
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "insurance_companies": [
      {
        "id": 1,
        "name": "Life Insurance Corporation of India",
        "code": "LIC",
        "status": "Active",
        "contact_person": "Mr. Rajesh Kumar",
        "email": "info@licindia.com",
        "mobile": "9876543210",
        "address": "Mumbai, Maharashtra",
        "created_at": "2024-01-15 10:00:00",
        "updated_at": "2024-12-01 14:30:00"
      },
      {
        "id": 2,
        "name": "Star Health and Allied Insurance Co. Ltd.",
        "code": "STAR",
        "status": "Active",
        "contact_person": "Ms. Priya Sharma",
        "email": "info@starhealth.in",
        "mobile": "9876543211",
        "address": "Chennai, Tamil Nadu",
        "created_at": "2024-01-15 10:00:00",
        "updated_at": "2024-12-01 14:30:00"
      },
      {
        "id": 3,
        "name": "HDFC ERGO Health Insurance",
        "code": "HDFC_ERGO",
        "status": "Active",
        "contact_person": "Mr. Amit Patel",
        "email": "contact@hdfcergo.com",
        "mobile": "9876543212",
        "address": "Pune, Maharashtra",
        "created_at": "2024-01-15 10:00:00",
        "updated_at": "2024-12-01 14:30:00"
      }
    ],
    "statistics": {
      "total_companies": 25,
      "active_companies": 23,
      "inactive_companies": 2
    },
    "pagination": {
      "current_page": 1,
      "per_page": 5,
      "total_companies": 25,
      "total_pages": 5
    }
  }
}
```

#### Active Companies Only
**Request:**
```http
GET /api/v1/mobile/agent/insurance_companies?status=active&page=1&per_page=20
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "insurance_companies": [
      {
        "id": 1,
        "name": "Life Insurance Corporation of India",
        "code": "LIC",
        "status": "Active",
        "contact_person": "Mr. Rajesh Kumar",
        "email": "info@licindia.com",
        "mobile": "9876543210",
        "address": "Mumbai, Maharashtra",
        "created_at": "2024-01-15 10:00:00",
        "updated_at": "2024-12-01 14:30:00"
      }
    ],
    "statistics": {
      "total_companies": 23,
      "active_companies": 23,
      "inactive_companies": 0
    },
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_companies": 23,
      "total_pages": 2
    }
  }
}
```

#### Search Companies
**Request:**
```http
GET /api/v1/mobile/agent/insurance_companies?search=LIC&page=1&per_page=20
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "insurance_companies": [
      {
        "id": 1,
        "name": "Life Insurance Corporation of India",
        "code": "LIC",
        "status": "Active",
        "contact_person": "Mr. Rajesh Kumar",
        "email": "info@licindia.com",
        "mobile": "9876543210",
        "address": "Mumbai, Maharashtra",
        "created_at": "2024-01-15 10:00:00",
        "updated_at": "2024-12-01 14:30:00"
      }
    ],
    "statistics": {
      "total_companies": 1,
      "active_companies": 1,
      "inactive_companies": 0
    },
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_companies": 1,
      "total_pages": 1
    }
  }
}
```

## Form Data Examples

### Get Form Data

**Request:**
```http
GET /api/v1/mobile/agent/form_data
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "clients": [
      {
        "id": 5,
        "name": "Priya Sharma",
        "email": "priya@example.com",
        "mobile": "9876543211"
      },
      {
        "id": 8,
        "name": "Amit Patel",
        "email": "amit@example.com",
        "mobile": "9876543212"
      }
    ],
    "insurance_companies": [
      {
        "id": 1,
        "name": "LIC of India"
      },
      {
        "id": 2,
        "name": "SBI Life Insurance"
      },
      {
        "id": 3,
        "name": "HDFC Life Insurance"
      },
      {
        "id": 4,
        "name": "ICICI Prudential Life Insurance"
      },
      {
        "id": 5,
        "name": "Star Health Insurance"
      },
      {
        "id": 6,
        "name": "HDFC ERGO Health Insurance"
      },
      {
        "id": 7,
        "name": "Care Health Insurance"
      },
      {
        "id": 8,
        "name": "Bajaj Allianz General Insurance"
      }
    ],
    "payment_modes": ["monthly", "quarterly", "half_yearly", "yearly", "single"],
    "policy_types": ["individual", "family", "group"],
    "insurance_types": ["health", "life", "motor", "other"],
    "policy_holder_options": ["self", "other"],
    "relationships": ["self", "spouse", "child", "father", "mother", "brother", "sister"],
    "document_types": ["policy_copy", "proposal_form", "medical_reports", "id_proof", "address_proof"],
    "lead_stages": [
      {"value": "consultation", "label": "Consultation"},
      {"value": "one_on_one", "label": "One-on-One"},
      {"value": "converted", "label": "Converted"},
      {"value": "policy_created", "label": "Policy Created"},
      {"value": "referral_settled", "label": "Referral Settled"}
    ],
    "lead_sources": [
      {"value": "online", "label": "Online"},
      {"value": "offline", "label": "Offline"},
      {"value": "agent_referral", "label": "Agent Referral"},
      {"value": "walk_in", "label": "Walk In"},
      {"value": "tele_calling", "label": "Tele Calling"},
      {"value": "campaign", "label": "Campaign"}
    ],
    "product_interests": [
      {"value": "health", "label": "Health Insurance"},
      {"value": "life", "label": "Life Insurance"},
      {"value": "motor", "label": "Motor Insurance"},
      {"value": "home", "label": "Home Insurance"},
      {"value": "travel", "label": "Travel Insurance"},
      {"value": "other", "label": "Other Insurance"}
    ],
    "priority_levels": [
      {"value": "high", "label": "High"},
      {"value": "medium", "label": "Medium"},
      {"value": "low", "label": "Low"}
    ],
    "states": [
      {"value": "andhra_pradesh", "label": "Andhra Pradesh"},
      {"value": "assam", "label": "Assam"},
      {"value": "bihar", "label": "Bihar"},
      {"value": "delhi", "label": "Delhi"},
      {"value": "gujarat", "label": "Gujarat"},
      {"value": "haryana", "label": "Haryana"},
      {"value": "karnataka", "label": "Karnataka"},
      {"value": "kerala", "label": "Kerala"},
      {"value": "madhya_pradesh", "label": "Madhya Pradesh"},
      {"value": "maharashtra", "label": "Maharashtra"},
      {"value": "punjab", "label": "Punjab"},
      {"value": "rajasthan", "label": "Rajasthan"},
      {"value": "tamil_nadu", "label": "Tamil Nadu"},
      {"value": "uttar_pradesh", "label": "Uttar Pradesh"},
      {"value": "west_bengal", "label": "West Bengal"}
    ],
    "customer_types": ["individual", "corporate"],
    "genders": ["Male", "Female", "Other"],
    "marital_statuses": ["Single", "Married", "Divorced", "Widowed"],
    "vehicle_types": ["Two Wheeler", "Four Wheeler", "Commercial Vehicle"],
    "coverage_types": ["Property", "Travel", "Personal Accident", "Fire", "Marine", "Cyber Security", "Other"]
  }
}
```

## Error Response Examples

### Unauthorized Access

**Request:**
```http
GET /api/v1/mobile/agent/dashboard
```

**Response (401):**
```json
{
  "success": false,
  "message": "Authorization token is required"
}
```

### Invalid Token

**Request:**
```http
GET /api/v1/mobile/agent/dashboard
Authorization: Bearer invalid_token_here
```

**Response (401):**
```json
{
  "success": false,
  "message": "Invalid authorization token"
}
```

### Agent Authorization Required

**Request:**
```http
GET /api/v1/mobile/agent/dashboard
Authorization: Bearer customer_token_here
```

**Response (401):**
```json
{
  "success": false,
  "message": "Agent authorization required"
}
```

### Server Error

**Response (500):**
```json
{
  "success": false,
  "message": "Internal server error occurred",
  "errors": [
    "Something went wrong. Please try again later."
  ]
}
```

---

**Note**: All timestamps in responses are in ISO format or formatted as 'YYYY-MM-DD HH:MM:SS' as specified. Replace `{{auth_token}}` with actual JWT token received from login endpoint.

For testing purposes, use the provided Postman collection which includes all these examples with proper test scripts.