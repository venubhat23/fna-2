# Complete API Documentation - InsureBook Admin System

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Admin/Web APIs](#adminweb-apis)
4. [Mobile APIs](#mobile-apis)
5. [Data Models](#data-models)
6. [Error Handling](#error-handling)
7. [Testing Examples](#testing-examples)

---

## Overview

**Base URL:** `http://localhost:3000`

The InsureBook Admin system provides comprehensive REST APIs for:
- Insurance policy management (Health, Life, Motor, Other)
- Customer and agent management
- Mobile app integration
- Administrative functions

---

## Authentication

### JWT Token Format
```
Authorization: Bearer <jwt_token>
```

### Token Expiry
- **Web APIs:** 24 hours
- **Mobile APIs:** 30 days

---

## Admin/Web APIs

### 1. Authentication APIs

**Base Path:** `/api/v1/auth`

#### 1.1 User Login
```
POST /api/v1/auth/login
```

**Request:**
```json
{
  "email": "admin@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": 1,
      "email": "admin@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "mobile": "9876543210",
      "user_type": "agent",
      "agent_role": "admin",
      "status": true,
      "created_at": "2025-12-08T10:00:00Z"
    }
  }
}
```

#### 1.2 User Registration
```
POST /api/v1/auth/register
```

**Request:**
```json
{
  "first_name": "Jane",
  "last_name": "Smith",
  "email": "jane@example.com",
  "mobile": "9876543211",
  "password": "password123",
  "password_confirmation": "password123"
}
```

#### 1.3 Forgot Password
```
POST /api/v1/auth/forgot_password
```

**Request:**
```json
{
  "email": "admin@example.com"
}
```

#### 1.4 Reset Password
```
POST /api/v1/auth/reset_password
```

**Request:**
```json
{
  "reset_token": "abc123...",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

---

### 2. Customer Management APIs

**Base Path:** `/api/v1/customers`

#### 2.1 List Customers
```
GET /api/v1/customers
```

**Query Parameters:**
- `search` - Search by name, email, mobile, PAN
- `customer_type` - Filter by "individual" or "corporate"
- `status` - Filter by true/false (active/inactive)
- `limit` - Records per page (default: 50)
- `offset` - Pagination offset

**Response:**
```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": 1,
        "customer_type": "individual",
        "first_name": "Rajesh",
        "last_name": "Kumar",
        "email": "rajesh@example.com",
        "mobile": "9876543210",
        "birth_date": "1985-05-15",
        "age": 38,
        "gender": "Male",
        "address": "123 MG Road",
        "city": "Bangalore",
        "state": "Karnataka",
        "pincode": "560001",
        "pan_no": "ABCDE1234F",
        "occupation": "Software Engineer",
        "annual_income": "1200000",
        "marital_status": "Married",
        "status": true,
        "policies_count": 3,
        "total_premium": 45000.0,
        "family_members_count": 2,
        "created_at": "2025-12-01T10:00:00Z"
      }
    ],
    "pagination": {
      "total_count": 150,
      "current_page": 1,
      "total_pages": 3,
      "limit": 50,
      "offset": 0
    },
    "statistics": {
      "total_customers": 150,
      "individual_customers": 140,
      "corporate_customers": 10,
      "active_customers": 145,
      "inactive_customers": 5
    }
  }
}
```

#### 2.2 Get Customer Details
```
GET /api/v1/customers/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "customer": {
      "id": 1,
      "customer_type": "individual",
      "first_name": "Rajesh",
      "last_name": "Kumar",
      "company_name": null,
      "email": "rajesh@example.com",
      "mobile": "9876543210",
      "birth_date": "1985-05-15",
      "age": 38,
      "gender": "Male",
      "address": "123 MG Road",
      "city": "Bangalore",
      "state": "Karnataka",
      "pincode": "560001",
      "pan_no": "ABCDE1234F",
      "gst_no": null,
      "occupation": "Software Engineer",
      "annual_income": "1200000",
      "marital_status": "Married",
      "education": "Graduate",
      "status": true,
      "family_members": [
        {
          "id": 1,
          "name": "Priya Kumar",
          "relationship": "Spouse",
          "birth_date": "1988-08-20",
          "age": 35,
          "gender": "Female"
        }
      ],
      "policies": [
        {
          "id": 1,
          "type": "Health",
          "policy_number": "HP123456",
          "plan_name": "Health Plus",
          "sum_insured": 500000,
          "premium": 25000,
          "status": "Active",
          "start_date": "2025-01-01",
          "end_date": "2025-12-31"
        }
      ]
    }
  }
}
```

#### 2.3 Create Customer
```
POST /api/v1/customers
```

**Request:**
```json
{
  "customer_type": "individual",
  "first_name": "Amit",
  "last_name": "Patel",
  "email": "amit@example.com",
  "mobile": "9876543212",
  "birth_date": "1990-03-15",
  "gender": "Male",
  "address": "456 Park Street",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "pan_no": "FGHIJ5678K",
  "occupation": "Business",
  "annual_income": "800000",
  "marital_status": "Single"
}
```

#### 2.4 Update Customer
```
PUT /api/v1/customers/:id
```

#### 2.5 Toggle Customer Status
```
PATCH /api/v1/customers/:id/toggle_status
```

---

### 3. Health Insurance APIs

**Base Path:** `/api/v1/health_insurances`

#### 3.1 List Health Insurance Policies
```
GET /api/v1/health_insurances
```

**Query Parameters:**
- `search` - Search by policy number, plan name, company, customer
- `status` - "active", "expired", "expiring_soon"
- `insurance_type` - "Individual", "Family Floater", "Group"
- `company` - Insurance company name
- `start_date` & `end_date` - Date range filter
- `limit` & `offset` - Pagination

**Response:**
```json
{
  "success": true,
  "data": {
    "health_insurances": [
      {
        "id": 1,
        "policy_number": "HP123456",
        "plan_name": "Health Plus Plan",
        "customer": {
          "id": 1,
          "name": "Rajesh Kumar",
          "mobile": "9876543210"
        },
        "sub_agent": {
          "id": 1,
          "name": "Agent Name"
        },
        "policy_holder": "Rajesh Kumar",
        "insurance_company_name": "Star Health",
        "insurance_type": "Individual",
        "policy_type": "New",
        "policy_start_date": "2025-01-01",
        "policy_end_date": "2025-12-31",
        "payment_mode": "Yearly",
        "sum_insured": 500000.0,
        "net_premium": 21186.0,
        "gst_percentage": 18.0,
        "gst_amount": 3813.0,
        "total_premium": 25000.0,
        "agent_commission_percentage": 10.0,
        "commission_amount": 2500.0,
        "tds_applicable": false,
        "tds_percentage": 0.0,
        "status": "active",
        "days_until_expiry": 358,
        "family_members": [
          {
            "id": 1,
            "name": "Priya Kumar",
            "relationship": "Spouse",
            "sum_insured": 500000.0
          }
        ],
        "created_at": "2025-01-01T10:00:00Z"
      }
    ],
    "pagination": {
      "total_count": 25,
      "current_page": 1,
      "total_pages": 3,
      "limit": 10,
      "offset": 0
    }
  }
}
```

#### 3.2 Create Health Insurance Policy
```
POST /api/v1/health_insurances
```

**Request:**
```json
{
  "customer_id": 1,
  "sub_agent_id": 1,
  "agency_code_id": 1,
  "broker_id": 1,
  "policy_number": "HP123456",
  "plan_name": "Health Plus Plan",
  "policy_holder": "Rajesh Kumar",
  "insurance_company_name": "Star Health Insurance",
  "insurance_type": "Individual",
  "policy_type": "New",
  "policy_start_date": "2025-01-01",
  "policy_end_date": "2025-12-31",
  "payment_mode": "Yearly",
  "sum_insured": 500000.0,
  "net_premium": 21186.0,
  "gst_percentage": 18.0,
  "total_premium": 25000.0,
  "agent_commission_percentage": 10.0,
  "commission_amount": 2500.0,
  "tds_applicable": false,
  "family_members_attributes": [
    {
      "name": "Priya Kumar",
      "relationship": "Spouse",
      "birth_date": "1988-08-20",
      "gender": "Female",
      "sum_insured": 500000.0
    }
  ]
}
```

#### 3.3 Get Health Insurance Statistics
```
GET /api/v1/health_insurances/statistics
```

**Response:**
```json
{
  "success": true,
  "data": {
    "statistics": {
      "total_policies": 25,
      "active_policies": 22,
      "expired_policies": 3,
      "expiring_soon": 5,
      "total_sum_insured": 12500000.0,
      "total_premium": 625000.0,
      "total_commission": 62500.0,
      "this_month": {
        "new_policies": 3,
        "renewals": 2,
        "premium": 75000.0
      }
    }
  }
}
```

#### 3.4 Get Form Data
```
GET /api/v1/health_insurances/form_data
```

**Response:**
```json
{
  "success": true,
  "data": {
    "insurance_companies": ["Star Health", "HDFC ERGO", "Care Health"],
    "insurance_types": ["Individual", "Family Floater", "Group"],
    "policy_types": ["New", "Renewal", "Porting", "Migration"],
    "payment_modes": ["Yearly", "Half Yearly", "Quarterly", "Monthly", "Single"],
    "relationships": ["Self", "Spouse", "Son", "Daughter", "Father", "Mother"],
    "genders": ["Male", "Female", "Other"]
  }
}
```

---

### 4. Life Insurance APIs

**Base Path:** `/api/v1/life_insurances`

#### 4.1 List Life Insurance Policies
```
GET /api/v1/life_insurances
```

**Response Structure:** Similar to Health Insurance with additional fields:
```json
{
  "policy_term": 20,
  "premium_payment_term": 10,
  "nominee_name": "Priya Kumar",
  "nominee_relationship": "Spouse",
  "gst_1st_year": 18.0,
  "gst_2nd_year": 18.0,
  "gst_3rd_year": 18.0,
  "riders": [
    {
      "rider_type": "Term",
      "rider_name": "Accidental Death Benefit",
      "sum_assured": 100000.0,
      "premium": 500.0
    }
  ],
  "bank_details": {
    "bank_name": "HDFC Bank",
    "account_number": "12345678901",
    "ifsc_code": "HDFC0000123"
  }
}
```

#### 4.2 Create Life Insurance Policy
```
POST /api/v1/life_insurances
```

**Request includes additional life insurance specific fields:**
```json
{
  "policy_term": 20,
  "premium_payment_term": 10,
  "nominee_name": "Priya Kumar",
  "nominee_relationship": "Spouse",
  "gst_1st_year": 18.0,
  "gst_2nd_year": 18.0,
  "gst_3rd_year": 18.0,
  "riders_attributes": [
    {
      "rider_type": "Term",
      "rider_name": "Accidental Death Benefit",
      "sum_assured": 100000.0,
      "premium": 500.0
    }
  ]
}
```

---

### 5. Sub Agent Management APIs

**Base Path:** `/api/v1/sub_agents`

#### 5.1 List Sub Agents
```
GET /api/v1/sub_agents
```

**Query Parameters:**
- `search` - Search by name, mobile, email
- `status` - "active" or "inactive"
- `limit` & `offset` - Pagination

**Response:**
```json
{
  "success": true,
  "data": {
    "sub_agents": [
      {
        "id": 1,
        "first_name": "Test",
        "middle_name": null,
        "last_name": "Agent",
        "full_name": "Test Agent",
        "display_name": "Test Agent",
        "mobile": "9876543211",
        "email": "agent@example.com",
        "role_id": 1,
        "birth_date": null,
        "gender": "Male",
        "pan_no": null,
        "gst_no": null,
        "company_name": null,
        "address": null,
        "bank_name": null,
        "account_no": null,
        "ifsc_code": null,
        "account_holder_name": null,
        "account_type": null,
        "upi_id": null,
        "status": "active",
        "created_at": "2025-12-07T04:59:45.927Z",
        "updated_at": "2025-12-07T04:59:45.927Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 1,
      "total_count": 2,
      "per_page": 20
    },
    "statistics": {
      "total_sub_agents": 2,
      "active_sub_agents": 2,
      "inactive_sub_agents": 0
    }
  }
}
```

#### 5.2 Create Sub Agent
```
POST /api/v1/sub_agents
```

**Request:**
```json
{
  "first_name": "New",
  "middle_name": "Sub",
  "last_name": "Agent",
  "mobile": "9876543213",
  "email": "newagent@example.com",
  "role_id": 1,
  "gender": "Male",
  "birth_date": "1990-01-01",
  "pan_no": "ABCDE1234F",
  "gst_no": "GST123456789",
  "address": "123 Agent Street",
  "bank_name": "SBI",
  "account_no": "12345678901",
  "ifsc_code": "SBIN0000123",
  "account_holder_name": "New Sub Agent",
  "account_type": "Savings",
  "upi_id": "agent@paytm"
}
```

---

## Mobile APIs

### 1. Mobile Authentication APIs

**Base Path:** `/api/v1/mobile/auth`

#### 1.1 Mobile Login (Multi-Role)
```
POST /api/v1/mobile/auth/login
```

**Request:**
```json
{
  "username": "customer@example.com",
  "password": "password123"
}
```

**Response (Customer):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "username": "Rajesh Kumar",
    "role": "customer",
    "user_id": 1,
    "email": "customer@example.com",
    "mobile": "9876543210"
  }
}
```

**Response (Agent):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "username": "John Doe",
    "role": "agent",
    "user_id": 4,
    "email": "admin@example.com",
    "commission_earned": 15000.0,
    "customers_count": 25,
    "policies_count": 50
  }
}
```

**Response (Sub Agent):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "username": "Test Agent",
    "role": "sub_agent",
    "user_id": 1,
    "email": "agent@example.com",
    "mobile": "9876543211",
    "commission_earned": 8000.0,
    "customers_count": 12,
    "policies_count": 20
  }
}
```

#### 1.2 Mobile Customer Registration
```
POST /api/v1/mobile/auth/register
```

**Request:**
```json
{
  "first_name": "New",
  "last_name": "Customer",
  "email": "newcustomer@example.com",
  "mobile": "9876543214",
  "password": "password123"
}
```

---

### 2. Mobile Customer APIs

**Base Path:** `/api/v1/mobile/customer`

#### 2.1 Customer Portfolio
```
GET /api/v1/mobile/customer/portfolio
```

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "customer_info": {
      "name": "Rajesh Kumar",
      "email": "rajesh@example.com",
      "mobile": "9876543210",
      "customer_id": 1
    },
    "portfolio_summary": {
      "total_policies": 3,
      "active_policies": 2,
      "expired_policies": 0,
      "expiring_soon": 1,
      "total_sum_insured": 1500000.0,
      "total_premium": 65000.0
    },
    "health_insurances": [
      {
        "id": 1,
        "policy_number": "HP123456",
        "plan_name": "Health Plus Plan",
        "insurance_company": "Star Health",
        "sum_insured": 500000.0,
        "premium": 25000.0,
        "start_date": "2025-01-01",
        "end_date": "2025-12-31",
        "status": "Active",
        "days_until_expiry": 358,
        "family_members": ["Priya Kumar"]
      }
    ],
    "life_insurances": [
      {
        "id": 1,
        "policy_number": "LI789012",
        "plan_name": "Term Plan",
        "insurance_company": "LIC of India",
        "sum_insured": 1000000.0,
        "premium": 15000.0,
        "start_date": "2025-01-01",
        "end_date": "2045-12-31",
        "status": "Active",
        "nominee": "Priya Kumar"
      }
    ]
  }
}
```

#### 2.2 Upcoming Installments
```
GET /api/v1/mobile/customer/upcoming_installments
```

**Response:**
```json
{
  "success": true,
  "data": {
    "upcoming_installments": [
      {
        "policy_id": 1,
        "policy_number": "HP123456",
        "policy_type": "Health",
        "plan_name": "Health Plus Plan",
        "due_date": "2025-12-31",
        "amount": 25000.0,
        "days_until_due": 23,
        "status": "Due Soon"
      }
    ]
  }
}
```

#### 2.3 Upcoming Renewals
```
GET /api/v1/mobile/customer/upcoming_renewals
```

**Response:**
```json
{
  "success": true,
  "data": {
    "upcoming_renewals": [
      {
        "policy_id": 1,
        "policy_number": "HP123456",
        "policy_type": "Health",
        "plan_name": "Health Plus Plan",
        "expiry_date": "2025-12-31",
        "days_until_expiry": 23,
        "current_premium": 25000.0,
        "sum_insured": 500000.0
      }
    ]
  }
}
```

---

### 3. Mobile Agent APIs

**Base Path:** `/api/v1/mobile/agent`

#### 3.1 Agent Dashboard
```
GET /api/v1/mobile/agent/dashboard
```

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "agent_info": {
      "name": "John Doe",
      "email": "admin@example.com",
      "mobile": "9876543210",
      "role": "agent"
    },
    "statistics": {
      "customers_count": 25,
      "policies_count": 50,
      "health_policies_count": 30,
      "life_policies_count": 15,
      "motor_policies_count": 3,
      "other_policies_count": 2,
      "total_premium": 1250000.0,
      "commission_earned": 125000.0,
      "this_month_policies": 8,
      "this_month_premium": 200000.0
    },
    "recent_activities": [
      {
        "type": "policy_created",
        "message": "Health insurance policy HP123456 created for Rajesh Kumar",
        "timestamp": "2025-12-08T10:30:00Z",
        "policy_type": "Health"
      },
      {
        "type": "policy_created",
        "message": "Life insurance policy LI789012 created for Priya Sharma",
        "timestamp": "2025-12-07T15:45:00Z",
        "policy_type": "Life"
      }
    ]
  }
}
```

#### 3.2 Agent Customers
```
GET /api/v1/mobile/agent/customers
```

**Query Parameters:**
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 10)

**Response:**
```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": 1,
        "name": "Rajesh Kumar",
        "mobile": "9876543210",
        "email": "rajesh@example.com",
        "customer_type": "individual",
        "status": "Active",
        "policies_count": 3,
        "total_premium": 65000.0,
        "created_at": "2025-12-01T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_customers": 25,
      "total_pages": 3
    }
  }
}
```

#### 3.3 Add Customer (Agent)
```
POST /api/v1/mobile/agent/customers
```

**Request:**
```json
{
  "customer_type": "individual",
  "first_name": "New",
  "last_name": "Customer",
  "email": "newcustomer@example.com",
  "mobile": "9876543215",
  "gender": "Male",
  "birth_date": "1985-06-15",
  "address": "789 New Street",
  "city": "Delhi",
  "state": "Delhi",
  "pincode": "110001",
  "pan_no": "NEWPAN123F",
  "occupation": "Teacher",
  "annual_income": "600000",
  "marital_status": "Married"
}
```

#### 3.4 Agent Policies
```
GET /api/v1/mobile/agent/policies
```

**Query Parameters:**
- `policy_type` - Filter by "health", "life", "motor", "other", or "all"
- `page` - Page number
- `per_page` - Items per page

**Response:**
```json
{
  "success": true,
  "data": {
    "policies": [
      {
        "id": 1,
        "insurance_name": "Health Plus Plan",
        "insurance_type": "Health",
        "policy_number": "HP123456",
        "client_name": "Rajesh Kumar",
        "policy_type": "new_policy",
        "policy_holder": "Rajesh Kumar",
        "entry_date": "2025-12-01",
        "start_date": "2025-01-01",
        "end_date": "2025-12-31",
        "total_premium": 25000.0,
        "sum_insured": 500000.0,
        "insurance_company": "Star Health Insurance",
        "payment_mode": "yearly",
        "commission_amount": 2500.0,
        "status": "Active"
      },
      {
        "id": 2,
        "insurance_name": "Comprehensive Car Insurance",
        "insurance_type": "Motor",
        "policy_number": "MC345678",
        "client_name": "Amit Patel",
        "policy_type": "new_policy",
        "policy_holder": "Amit Patel",
        "entry_date": "2025-12-08",
        "start_date": "2025-12-08",
        "end_date": "2026-12-07",
        "total_premium": 30000.0,
        "sum_insured": 800000.0,
        "insurance_company": "Bajaj Allianz General Insurance",
        "payment_mode": "yearly",
        "commission_amount": 4500.0,
        "status": "Active"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_policies": 50,
      "total_pages": 5
    }
  }
}
```

#### 3.5 Add Health Policy (Agent)
```
POST /api/v1/mobile/agent/policies/health
```

**Request:**
```json
{
  "customer_id": 1,
  "policy_holder": "Rajesh Kumar",
  "plan_name": "Health Plus Plan",
  "policy_number": "HP123456",
  "insurance_company_name": "Star Health Insurance",
  "policy_type": "new_policy",
  "policy_start_date": "2025-01-01",
  "policy_end_date": "2025-12-31",
  "payment_mode": "yearly",
  "sum_insured": 500000.0,
  "net_premium": 21186.0,
  "gst_percentage": 18.0,
  "total_premium": 25000.0,
  "agent_commission_percentage": 10.0,
  "commission_amount": 2500.0
}
```

#### 3.6 Add Life Policy (Agent)
```
POST /api/v1/mobile/agent/policies/life
```

**Request:**
```json
{
  "customer_id": 2,
  "policy_holder": "Priya Sharma",
  "plan_name": "Term Life Plan",
  "policy_number": "LI789012",
  "insurance_company_name": "LIC of India",
  "policy_type": "new_policy",
  "policy_start_date": "2025-01-01",
  "policy_end_date": "2045-12-31",
  "payment_mode": "yearly",
  "policy_term": 20,
  "premium_payment_term": 10,
  "sum_insured": 1000000.0,
  "net_premium": 12712.0,
  "total_premium": 15000.0,
  "nominee_name": "Rahul Sharma",
  "nominee_relationship": "Spouse",
  "agent_commission_percentage": 10.0,
  "commission_amount": 1500.0
}
```

#### 3.7 Add Motor Policy (Agent)
```
POST /api/v1/mobile/agent/policies/motor
```

**Request:**
```json
{
  "customer_id": 3,
  "policy_holder": "Amit Patel",
  "plan_name": "Comprehensive Car Insurance",
  "policy_number": "MC345678",
  "insurance_company_name": "Bajaj Allianz General Insurance",
  "policy_type": "new_policy",
  "policy_start_date": "2025-12-08",
  "policy_end_date": "2026-12-07",
  "payment_mode": "yearly",
  "sum_insured": 800000.0,
  "net_premium": 25424.0,
  "gst_percentage": 18.0,
  "total_premium": 30000.0,
  "agent_commission_percentage": 15.0,
  "commission_amount": 4500.0,
  "vehicle_make": "Maruti Suzuki",
  "vehicle_model": "Swift",
  "vehicle_number": "KA01AB1234",
  "vehicle_year": 2022,
  "engine_number": "ENG123456789",
  "chassis_number": "CHA987654321",
  "vehicle_type": "Four Wheeler"
}
```

#### 3.8 Add Other Policy (Agent)
```
POST /api/v1/mobile/agent/policies/other
```

**Request:**
```json
{
  "customer_id": 4,
  "policy_holder": "Suresh Reddy",
  "plan_name": "Travel Insurance Premium",
  "policy_number": "TI567890",
  "insurance_company_name": "HDFC ERGO General Insurance",
  "policy_type": "new_policy",
  "policy_start_date": "2025-12-10",
  "policy_end_date": "2026-12-09",
  "payment_mode": "yearly",
  "sum_insured": 200000.0,
  "net_premium": 8475.0,
  "gst_percentage": 18.0,
  "total_premium": 10000.0,
  "agent_commission_percentage": 20.0,
  "commission_amount": 2000.0,
  "coverage_type": "Travel",
  "description": "Comprehensive travel insurance for international trips"
}
```

#### 3.9 Get Form Data (Agent)
```
GET /api/v1/mobile/agent/form_data
```

**Response:**
```json
{
  "success": true,
  "data": {
    "insurance_companies": [
      "LIC of India",
      "SBI Life Insurance",
      "HDFC Life Insurance",
      "ICICI Prudential Life Insurance",
      "Bajaj Allianz Life Insurance",
      "Star Health Insurance",
      "HDFC ERGO Health Insurance",
      "Care Health Insurance",
      "Bajaj Allianz General Insurance"
    ],
    "payment_modes": [
      "monthly",
      "quarterly",
      "half_yearly",
      "yearly",
      "single"
    ],
    "policy_types": [
      "new_policy",
      "renewal"
    ],
    "customer_types": [
      "individual",
      "corporate"
    ],
    "genders": [
      "Male",
      "Female",
      "Other"
    ],
    "marital_statuses": [
      "Single",
      "Married",
      "Divorced",
      "Widowed"
    ],
    "vehicle_types": [
      "Two Wheeler",
      "Four Wheeler",
      "Commercial Vehicle"
    ],
    "coverage_types": [
      "Property",
      "Travel",
      "Personal Accident",
      "Fire",
      "Marine",
      "Cyber Security",
      "Other"
    ],
    "insurance_types": [
      "health",
      "life",
      "motor",
      "other"
    ]
  }
}
```

---

### 4. Mobile Settings APIs

**Base Path:** `/api/v1/mobile/settings`

#### 4.1 Get Profile
```
GET /api/v1/mobile/settings/profile
```

#### 4.2 Update Profile
```
PUT /api/v1/mobile/settings/profile
```

#### 4.3 Change Password
```
POST /api/v1/mobile/settings/change_password
```

#### 4.4 Terms and Conditions
```
GET /api/v1/mobile/settings/terms
```

#### 4.5 Contact Information
```
GET /api/v1/mobile/settings/contact
```

#### 4.6 Submit Helpdesk Request
```
POST /api/v1/mobile/settings/helpdesk
```

#### 4.7 Notification Settings
```
GET /api/v1/mobile/settings/notifications
PUT /api/v1/mobile/settings/notifications
```

---

## Data Models

### Core Models and Relationships

#### Customer Model
```json
{
  "id": "integer",
  "customer_type": "individual|corporate",
  "first_name": "string",
  "last_name": "string",
  "company_name": "string (for corporate)",
  "email": "string",
  "mobile": "string",
  "birth_date": "date",
  "gender": "Male|Female|Other",
  "address": "text",
  "city": "string",
  "state": "string",
  "pincode": "string",
  "pan_no": "string",
  "gst_no": "string",
  "occupation": "string",
  "annual_income": "decimal",
  "marital_status": "Single|Married|Divorced|Widowed",
  "education": "string",
  "status": "boolean",
  "added_by": "string",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

#### Health Insurance Model
```json
{
  "id": "integer",
  "customer_id": "foreign_key",
  "sub_agent_id": "foreign_key",
  "agency_code_id": "foreign_key",
  "broker_id": "foreign_key",
  "policy_number": "string",
  "plan_name": "string",
  "policy_holder": "string",
  "insurance_company_name": "string",
  "insurance_type": "Individual|Family Floater|Group",
  "policy_type": "New|Renewal|Porting|Migration",
  "policy_start_date": "date",
  "policy_end_date": "date",
  "payment_mode": "Yearly|Half Yearly|Quarterly|Monthly|Single",
  "sum_insured": "decimal",
  "net_premium": "decimal",
  "gst_percentage": "decimal",
  "gst_amount": "decimal",
  "total_premium": "decimal",
  "agent_commission_percentage": "decimal",
  "commission_amount": "decimal",
  "tds_applicable": "boolean",
  "tds_percentage": "decimal",
  "status": "string",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

#### Life Insurance Model
```json
{
  "id": "integer",
  "customer_id": "foreign_key",
  "sub_agent_id": "foreign_key",
  "policy_term": "integer",
  "premium_payment_term": "integer",
  "nominee_name": "string",
  "nominee_relationship": "string",
  "gst_1st_year": "decimal",
  "gst_2nd_year": "decimal",
  "gst_3rd_year": "decimal",
  "bank_name": "string",
  "account_number": "string",
  "ifsc_code": "string",
  "bonus_rate": "decimal",
  "fund_name": "string"
}
```

#### Policy Model (for Motor/Other)
```json
{
  "id": "integer",
  "customer_id": "foreign_key",
  "user_id": "foreign_key",
  "insurance_company_id": "foreign_key",
  "agency_broker_id": "foreign_key",
  "policy_number": "string",
  "plan_name": "string",
  "insurance_type": "life|health|motor|other",
  "policy_type": "new_policy|renewal",
  "policy_start_date": "date",
  "policy_end_date": "date",
  "payment_mode": "yearly|half_yearly|quarterly|monthly|single",
  "sum_insured": "decimal",
  "net_premium": "decimal",
  "gst_percentage": "decimal",
  "total_premium": "decimal",
  "agent_commission_percentage": "decimal",
  "commission_amount": "decimal",
  "status": "boolean"
}
```

---

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "errors": ["Detailed error messages"]
}
```

### HTTP Status Codes
- `200` - OK (Success)
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `422` - Unprocessable Entity (Validation errors)
- `500` - Internal Server Error

### Common Error Examples

#### Authentication Required
```json
{
  "success": false,
  "message": "Authorization token is required"
}
```

#### Invalid Token
```json
{
  "success": false,
  "message": "Invalid authorization token"
}
```

#### Validation Errors
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "Email has already been taken",
    "Mobile number is invalid",
    "Policy number can't be blank"
  ]
}
```

#### Resource Not Found
```json
{
  "success": false,
  "message": "Customer not found"
}
```

---

## Testing Examples

### Using cURL

#### 1. Authentication
```bash
# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'

# Mobile Login
curl -X POST http://localhost:3000/api/v1/mobile/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@example.com","password":"password123"}'
```

#### 2. Customer Management
```bash
# Get customers
curl -X GET "http://localhost:3000/api/v1/customers?limit=10&offset=0" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"

# Create customer
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"customer_type":"individual","first_name":"Test","last_name":"Customer","email":"test@example.com","mobile":"9876543210"}'
```

#### 3. Policy Management
```bash
# Get health insurances
curl -X GET "http://localhost:3000/api/v1/health_insurances?limit=10" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"

# Create health insurance
curl -X POST http://localhost:3000/api/v1/health_insurances \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"customer_id":1,"policy_number":"HP123456","plan_name":"Health Plus","sum_insured":500000,"total_premium":25000}'
```

#### 4. Mobile APIs
```bash
# Agent dashboard
curl -X GET http://localhost:3000/api/v1/mobile/agent/dashboard \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"

# Customer portfolio
curl -X GET http://localhost:3000/api/v1/mobile/customer/portfolio \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

### Using Postman

Import the provided Postman collection files:
- `InsureBook_Admin_API_Collection.postman_collection.json`
- `InsureBook_Admin_Environment.postman_environment.json`

---

## API Endpoints Summary

### Total Endpoints: 70+

#### Authentication (4 endpoints)
- Login, Register, Forgot Password, Reset Password

#### Customer Management (6 endpoints)
- List, Show, Create, Update, Delete, Toggle Status

#### Health Insurance (8 endpoints)
- CRUD operations, Statistics, Form Data, Policy Holder Options

#### Life Insurance (8 endpoints)
- CRUD operations, Statistics, Form Data, Policy Holder Options

#### Sub Agent Management (6 endpoints)
- CRUD operations, Toggle Status

#### Mobile Authentication (3 endpoints)
- Login, Register, Forgot Password

#### Mobile Customer (4 endpoints)
- Portfolio, Upcoming Installments, Renewals, Add Policy

#### Mobile Agent (9 endpoints)
- Dashboard, Customers, Policies, Add Policies (Health/Life/Motor/Other), Form Data

#### Mobile Settings (8 endpoints)
- Profile, Change Password, Terms, Contact, Helpdesk, Notifications

---

This documentation provides comprehensive coverage of all API endpoints in the InsureBook Admin system with detailed request/response examples, error handling, and testing guidance.