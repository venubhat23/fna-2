# Mobile API Documentation - Agent Dashboard

## Base URL
```
http://localhost:3000/api/v1/mobile
```

## Authentication
All agent endpoints require JWT token in Authorization header:
```
Authorization: Bearer <jwt_token>
```

---

## 1. Authentication APIs

### 1.1 Agent Login
**Endpoint:** `POST /auth/login`

**Request:**
```json
{
  "username": "admin@example.com",
  "password": "password123"
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0LCJyb2xlIjoiYWdlbnQiLCJleHAiOjE3Njc3NjAyNjN9.FnVeKOtpQEL0dX4FzK0MqPILigqrJj66fFXnDKJnvrY",
    "username": "John Doe",
    "role": "agent",
    "user_id": 4,
    "email": "admin@example.com",
    "commission_earned": 0.0,
    "customers_count": 4,
    "policies_count": 3
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Invalid username or password"
}
```

### 1.2 Forgot Password
**Endpoint:** `POST /auth/forgot_password`

**Request:**
```json
{
  "email": "admin@example.com"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Password reset instructions have been sent to your email"
}
```

---

## 2. Agent Dashboard APIs

### 2.1 Dashboard Overview
**Endpoint:** `GET /agent/dashboard`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
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
      "customers_count": 15,
      "policies_count": 25,
      "health_policies_count": 12,
      "life_policies_count": 8,
      "total_premium": 150000.0,
      "commission_earned": 15000.0,
      "this_month_policies": 5,
      "this_month_premium": 45000.0
    },
    "recent_activities": [
      {
        "type": "policy_created",
        "message": "Health insurance policy H123456 created for Rajesh Kumar",
        "timestamp": "2025-12-08T10:30:00Z",
        "policy_type": "Health"
      }
    ]
  }
}
```

---

## 3. Customer Management APIs

### 3.1 Get All Customers
**Endpoint:** `GET /agent/customers`

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 10)

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

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
        "total_premium": 45000.0,
        "created_at": "2025-12-01T10:00:00Z"
      },
      {
        "id": 2,
        "name": "Priya Sharma",
        "mobile": "9876543211",
        "email": "priya@example.com",
        "customer_type": "individual",
        "status": "Active",
        "policies_count": 2,
        "total_premium": 32000.0,
        "created_at": "2025-12-02T11:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_customers": 15,
      "total_pages": 2
    }
  }
}
```

### 3.2 Add Customer
**Endpoint:** `POST /agent/customers`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request:**
```json
{
  "customer_type": "individual",
  "first_name": "Amit",
  "last_name": "Patel",
  "email": "amit.patel@example.com",
  "mobile": "9876543212",
  "gender": "Male",
  "birth_date": "1985-05-15",
  "address": "123 MG Road, Bangalore",
  "city": "Bangalore",
  "state": "Karnataka",
  "pincode": "560001",
  "pan_no": "ABCDE1234F",
  "occupation": "Software Engineer",
  "annual_income": "1200000",
  "marital_status": "Married"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Customer added successfully",
  "data": {
    "customer_id": 16,
    "name": "Amit Patel",
    "email": "amit.patel@example.com",
    "mobile": "9876543212"
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Failed to add customer",
  "errors": [
    "Email has already been taken",
    "Mobile has already been taken"
  ]
}
```

---

## 4. Policy Management APIs

### 4.1 Get All Policies
**Endpoint:** `GET /agent/policies`

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 10)
- `policy_type` (optional): Filter by type (health, life, motor, other, all)

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

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
        "start_date": "2025-12-01",
        "end_date": "2026-11-30",
        "total_premium": 25000.0,
        "sum_insured": 500000.0,
        "insurance_company": "Star Health Insurance",
        "payment_mode": "yearly",
        "commission_amount": 2500.0,
        "status": "Active"
      },
      {
        "id": 2,
        "insurance_name": "Term Life Plan",
        "insurance_type": "Life",
        "policy_number": "TL789012",
        "client_name": "Priya Sharma",
        "policy_type": "new_policy",
        "policy_holder": "Priya Sharma",
        "entry_date": "2025-12-02",
        "start_date": "2025-12-02",
        "end_date": "2045-12-01",
        "total_premium": 15000.0,
        "sum_insured": 1000000.0,
        "insurance_company": "LIC of India",
        "payment_mode": "yearly",
        "commission_amount": 1500.0,
        "status": "Active"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_policies": 25,
      "total_pages": 3
    }
  }
}
```

### 4.2 Add Health Insurance Policy
**Endpoint:** `POST /agent/policies/health`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
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
  "policy_start_date": "2025-12-01",
  "policy_end_date": "2026-11-30",
  "payment_mode": "yearly",
  "sum_insured": 500000.0,
  "net_premium": 21186.0,
  "gst_percentage": 18.0,
  "total_premium": 25000.0,
  "agent_commission_percentage": 10.0,
  "commission_amount": 2500.0
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Health insurance policy added successfully",
  "data": {
    "id": 3,
    "insurance_name": "Health Plus Plan",
    "insurance_type": "Health",
    "policy_number": "HP123456",
    "client_name": "Rajesh Kumar",
    "policy_type": "new_policy",
    "policy_holder": "Rajesh Kumar",
    "entry_date": "2025-12-08",
    "start_date": "2025-12-01",
    "end_date": "2026-11-30",
    "total_premium": 25000.0,
    "sum_insured": 500000.0,
    "insurance_company": "Star Health Insurance",
    "payment_mode": "yearly",
    "commission_amount": 2500.0,
    "status": "Active"
  }
}
```

### 4.3 Add Life Insurance Policy
**Endpoint:** `POST /agent/policies/life`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request:**
```json
{
  "customer_id": 2,
  "policy_holder": "Priya Sharma",
  "plan_name": "Term Life Plan",
  "policy_number": "TL789012",
  "insurance_company_name": "LIC of India",
  "policy_type": "new_policy",
  "policy_start_date": "2025-12-02",
  "policy_end_date": "2045-12-01",
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

**Response (Success):**
```json
{
  "success": true,
  "message": "Life insurance policy added successfully",
  "data": {
    "id": 4,
    "insurance_name": "Term Life Plan",
    "insurance_type": "Life",
    "policy_number": "TL789012",
    "client_name": "Priya Sharma",
    "policy_type": "new_policy",
    "policy_holder": "Priya Sharma",
    "entry_date": "2025-12-08",
    "start_date": "2025-12-02",
    "end_date": "2045-12-01",
    "total_premium": 15000.0,
    "sum_insured": 1000000.0,
    "insurance_company": "LIC of India",
    "payment_mode": "yearly",
    "commission_amount": 1500.0,
    "status": "Active"
  }
}
```

### 4.4 Add Motor Insurance Policy
**Endpoint:** `POST /agent/policies/motor`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
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

**Response (Success):**
```json
{
  "success": true,
  "message": "Motor insurance policy added successfully",
  "data": {
    "id": 5,
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
}
```

### 4.5 Add Other Insurance Policy
**Endpoint:** `POST /agent/policies/other`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
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
  "description": "Comprehensive travel insurance for international trips with medical and baggage coverage"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Other insurance policy added successfully",
  "data": {
    "id": 6,
    "insurance_name": "Travel Insurance Premium",
    "insurance_type": "Other",
    "policy_number": "TI567890",
    "client_name": "Suresh Reddy",
    "policy_type": "new_policy",
    "policy_holder": "Suresh Reddy",
    "entry_date": "2025-12-08",
    "start_date": "2025-12-10",
    "end_date": "2026-12-09",
    "total_premium": 10000.0,
    "sum_insured": 200000.0,
    "insurance_company": "HDFC ERGO General Insurance",
    "payment_mode": "yearly",
    "commission_amount": 2000.0,
    "status": "Active"
  }
}
```

---

## 5. Form Data API

### 5.1 Get Form Data
**Endpoint:** `GET /agent/form_data`

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
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
      "Aditya Birla Sun Life Insurance",
      "Max Life Insurance",
      "Kotak Mahindra Life Insurance",
      "Tata AIA Life Insurance",
      "PNB MetLife India Insurance",
      "Star Health Insurance",
      "HDFC ERGO Health Insurance",
      "Care Health Insurance",
      "Niva Bupa Health Insurance",
      "Bajaj Allianz General Insurance",
      "New India Assurance",
      "Oriental Insurance",
      "United India Insurance"
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

## Error Responses

### Authentication Error
```json
{
  "success": false,
  "message": "Authorization token is required"
}
```

### Invalid Token
```json
{
  "success": false,
  "message": "Invalid authorization token"
}
```

### Validation Error
```json
{
  "success": false,
  "message": "Customer ID is required"
}
```

### Not Found Error
```json
{
  "success": false,
  "message": "Customer not found"
}
```

### Server Error
```json
{
  "success": false,
  "message": "Failed to add customer",
  "errors": [
    "Email has already been taken",
    "Mobile number is invalid"
  ]
}
```

---

## API Testing Examples

### Using cURL

1. **Login:**
```bash
curl -X POST http://localhost:3000/api/v1/mobile/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@example.com","password":"password123"}'
```

2. **Get Dashboard:**
```bash
curl -X GET http://localhost:3000/api/v1/mobile/agent/dashboard \
  -H "Authorization: Bearer <jwt_token>" \
  -H "Content-Type: application/json"
```

3. **Add Customer:**
```bash
curl -X POST http://localhost:3000/api/v1/mobile/agent/customers \
  -H "Authorization: Bearer <jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{"customer_type":"individual","first_name":"Test","last_name":"Customer","email":"test@example.com","mobile":"9876543210"}'
```

4. **Get Policies:**
```bash
curl -X GET "http://localhost:3000/api/v1/mobile/agent/policies?policy_type=health&page=1&per_page=5" \
  -H "Authorization: Bearer <jwt_token>" \
  -H "Content-Type: application/json"
```

---

## Response Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `409` - Conflict (e.g., duplicate data)
- `422` - Unprocessable Entity (validation errors)
- `500` - Internal Server Error

---

## Notes

1. All date fields should be in `YYYY-MM-DD` format
2. All monetary amounts are in INR (Indian Rupees)
3. JWT tokens expire after 30 days
4. All endpoints require valid authentication except login/register
5. Pagination starts from page 1
6. Default page size is 10 items per page
7. All timestamps are in ISO 8601 format (UTC)