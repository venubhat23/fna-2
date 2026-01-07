# Complete Mobile API Endpoints List

## All Available Mobile API Endpoints (25 endpoints)

### 1. Authentication APIs (3 endpoints)
```
POST   /api/v1/mobile/auth/login
POST   /api/v1/mobile/auth/register
POST   /api/v1/mobile/auth/forgot_password
```

### 2. Customer Mobile APIs (4 endpoints)
```
GET    /api/v1/mobile/customer/portfolio
GET    /api/v1/mobile/customer/upcoming_installments
GET    /api/v1/mobile/customer/upcoming_renewals
POST   /api/v1/mobile/customer/add_policy
```

### 3. Agent Mobile APIs (9 endpoints)
```
GET    /api/v1/mobile/agent/dashboard
GET    /api/v1/mobile/agent/customers
POST   /api/v1/mobile/agent/customers
GET    /api/v1/mobile/agent/policies
POST   /api/v1/mobile/agent/policies/health
POST   /api/v1/mobile/agent/policies/life
POST   /api/v1/mobile/agent/policies/motor
POST   /api/v1/mobile/agent/policies/other
GET    /api/v1/mobile/agent/form_data
```

### 4. Settings Mobile APIs (8 endpoints)
```
GET    /api/v1/mobile/settings/profile
PUT    /api/v1/mobile/settings/profile
POST   /api/v1/mobile/settings/change_password
GET    /api/v1/mobile/settings/terms
GET    /api/v1/mobile/settings/contact
POST   /api/v1/mobile/settings/helpdesk
GET    /api/v1/mobile/settings/notifications
PUT    /api/v1/mobile/settings/notifications
```

## Quick Copy-Paste Endpoint List

```
# Authentication
POST /api/v1/mobile/auth/login
POST /api/v1/mobile/auth/register
POST /api/v1/mobile/auth/forgot_password

# Customer APIs
GET /api/v1/mobile/customer/portfolio
GET /api/v1/mobile/customer/upcoming_installments
GET /api/v1/mobile/customer/upcoming_renewals
POST /api/v1/mobile/customer/add_policy

# Agent APIs
GET /api/v1/mobile/agent/dashboard
GET /api/v1/mobile/agent/customers
POST /api/v1/mobile/agent/customers
GET /api/v1/mobile/agent/policies
POST /api/v1/mobile/agent/policies/health
POST /api/v1/mobile/agent/policies/life
POST /api/v1/mobile/agent/policies/motor
POST /api/v1/mobile/agent/policies/other
GET /api/v1/mobile/agent/form_data

# Settings APIs
GET /api/v1/mobile/settings/profile
PUT /api/v1/mobile/settings/profile
POST /api/v1/mobile/settings/change_password
GET /api/v1/mobile/settings/terms
GET /api/v1/mobile/settings/contact
POST /api/v1/mobile/settings/helpdesk
GET /api/v1/mobile/settings/notifications
PUT /api/v1/mobile/settings/notifications
```

## Base URL
```
http://localhost:3000
```

## Authentication Header
```
Authorization: Bearer <jwt_token>
```

## Content Type Header
```
Content-Type: application/json
```