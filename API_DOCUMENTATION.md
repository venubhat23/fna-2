# InsureBook Mobile App - Authentication API Documentation

## Base URL
```
Production: https://your-production-domain.onrender.com/api/v1
Development: http://localhost:3000/api/v1
```

## Authentication APIs

### 1. User Registration API

**Endpoint:** `POST /auth/register`

**Description:** Register a new user (Agent/Sub-agent/Customer) in the InsureBook system.

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "mobile": "9876543210",
  "user_type": "agent",
  "role": "agent_role",
  "address": "123 Main Street",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pan_number": "ABCDE1234F",
  "gst_number": "12ABCDE1234F1Z5",
  "date_of_birth": "1990-01-15",
  "gender": "male",
  "occupation": "Insurance Agent",
  "annual_income": 500000.00
}
```

**Required Fields:**
- `first_name` (string)
- `last_name` (string)
- `email` (string, valid email format)
- `password` (string, minimum 6 characters)
- `password_confirmation` (string, must match password)
- `mobile` (string, 10 digits)

**Optional Fields:**
- `user_type` (string: "admin", "agent", "sub_agent")
- `role` (string: "super_admin", "admin_role", "manager", "agent_role")
- `address` (string)
- `city` (string)
- `state` (string)
- `pan_number` (string)
- `gst_number` (string)
- `date_of_birth` (date: YYYY-MM-DD)
- `gender` (string)
- `occupation` (string)
- `annual_income` (decimal)

**Success Response (201 Created):**
```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE2MzIzNTI4MDB9.abc123",
    "exp": "11-16-2024 18:30",
    "user": {
      "id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "full_name": "John Doe",
      "email": "john.doe@example.com",
      "mobile": "9876543210",
      "user_type": "agent",
      "role": "agent_role",
      "status": true,
      "address": "123 Main Street",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pan_number": "ABCDE1234F",
      "gst_number": "12ABCDE1234F1Z5",
      "date_of_birth": "1990-01-15",
      "gender": "male",
      "occupation": "Insurance Agent",
      "annual_income": "500000.0",
      "created_at": "2024-11-16T13:45:00.000Z",
      "updated_at": "2024-11-16T13:45:00.000Z"
    }
  }
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 6 characters)"
  ]
}
```

---

### 2. User Login API

**Endpoint:** `POST /auth/login`

**Description:** Authenticate user and get access token.

**Request Body:**
```json
{
  "email": "john.doe@example.com",
  "password": "password123"
}
```

**Required Fields:**
- `email` (string, valid email)
- `password` (string)

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE2MzIzNTI4MDB9.abc123",
    "exp": "11-16-2024 18:30",
    "user": {
      "id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "full_name": "John Doe",
      "email": "john.doe@example.com",
      "mobile": "9876543210",
      "user_type": "agent",
      "role": "agent_role",
      "status": true,
      "address": "123 Main Street",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pan_number": "ABCDE1234F",
      "gst_number": "12ABCDE1234F1Z5",
      "date_of_birth": "1990-01-15",
      "gender": "male",
      "occupation": "Insurance Agent",
      "annual_income": "500000.0",
      "created_at": "2024-11-16T13:45:00.000Z",
      "updated_at": "2024-11-16T13:45:00.000Z"
    }
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

## Authentication Headers

For protected endpoints (future APIs), include the JWT token in the Authorization header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE2MzIzNTI4MDB9.abc123
```

## User Types and Roles

**User Types:**
- `admin` - Administrative users
- `agent` - Insurance agents
- `sub_agent` - Sub-agents

**Roles:**
- `super_admin` - Full system access
- `admin_role` - Admin privileges
- `manager` - Management level access
- `agent_role` - Agent level access

## Status Codes

- `200` - Success
- `201` - Created
- `401` - Unauthorized (Invalid credentials)
- `422` - Unprocessable Entity (Validation errors)
- `498` - Invalid/Expired Token

## Sample Test Data

For testing purposes, you can use these credentials:

**Admin User:**
- Email: `admin@insurebook.in`
- Password: `password`

**Agent User:**
- Email: `rajesh@insurebook.in`
- Password: `password`

## Error Handling

All error responses follow this format:
```json
{
  "success": false,
  "message": "Error description",
  "errors": ["Detailed error messages"]  // Optional, for validation errors
}
```

## Token Expiry

- JWT tokens expire after 24 hours
- Include token expiry time in the response (`exp` field)
- Mobile app should handle token refresh/re-login

## Security Notes

- All API requests must be made over HTTPS in production
- Store JWT tokens securely in mobile app
- Don't log sensitive information like passwords
- Implement proper input validation on mobile side as well

---

## Database Configuration

**Production (Render PostgreSQL):**
- Database: drwise_db
- Host: dpg-d4ctbr1r0fns73aavd9g-a
- Username: drwise_db_user
- Port: 5432

**Development:**
- SQLite3 for local development

---

**Contact Information:**
- Email: info@insurebook.in
- Phone: +91 75678-44567

**Company:** InsureBook Technology Pvt Ltd

**API Implementation Status:**
✅ User Registration API - Complete and tested
✅ User Login API - Complete and tested
✅ JWT Token Authentication - Working with 24-hour expiry
✅ Error Handling - Proper validation and error responses
✅ Database Integration - SQLite (dev) / PostgreSQL (production)