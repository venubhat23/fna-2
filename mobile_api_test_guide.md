# Mobile API Test Guide

This guide shows how to test all mobile APIs with the seeded data.

## Setup Complete ✅

The comprehensive mobile API seed data has been created successfully with:

### Test Customer
- **Email**: `installment.test@example.com`
- **Mobile**: `9999999999`
- **Customer ID**: 8

### Test Data Created
- **Health Insurance Policies**: 3 (with various payment modes and dates)
- **Life Insurance Policies**: 1 (monthly payment with upcoming installments)
- **Portfolio**: 4 total policies with different statuses
- **Upcoming Installments**: 2 policies with installments due within 30 days
- **Upcoming Renewals**: 1 policy expiring in 15 days

## API Testing Steps

### 1. Authentication (Login)

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"email":"installment.test@example.com","password":"dummy"}' \
  "http://localhost:3000/api/v1/mobile/auth/login"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "username": "TestInstallment Customer",
    "role": "customer",
    "user_id": 8,
    "email": "installment.test@example.com",
    "mobile": "9999999999"
  }
}
```

**Note**: Save the `token` from the response for subsequent API calls.

### 2. Customer Portfolio API

```bash
curl -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  "http://localhost:3000/api/v1/mobile/customer/portfolio"
```

**Expected Response:**
- 4 total policies (3 Health + 1 Life)
- Total premium: ₹1,72,280
- Total sum insured: ₹40,50,000
- Mix of different insurance companies and payment modes

### 3. Upcoming Installments API ⭐

```bash
curl -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  "http://localhost:3000/api/v1/mobile/customer/upcoming_installments"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "upcoming_installments": [
      {
        "id": 6,
        "insurance_name": "Term Life Protection Plan",
        "insurance_type": "Life",
        "policy_number": "LIF_MONTHLY_20251208063429",
        "next_installment_date": "2025-12-11",
        "installment_amount": "5900.0"
      },
      {
        "id": 11,
        "insurance_name": "Family Health Protection Plan",
        "insurance_type": "Health",
        "policy_number": "HLT_MONTHLY_20251208063429",
        "next_installment_date": "2025-12-13",
        "installment_amount": "2360.0"
      }
    ],
    "total_installments": 2,
    "total_amount": 8260.0
  }
}
```

### 4. Upcoming Renewals API

```bash
curl -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  "http://localhost:3000/api/v1/mobile/customer/upcoming_renewals"
```

**Expected Response:**
- 1 policy expiring in 15 days
- Health Plan Expiring Soon (Care Health Insurance Ltd)
- Renewal date: 2025-12-24

### 5. Settings Profile API

```bash
curl -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  "http://localhost:3000/api/v1/mobile/settings/profile"
```

**Expected Response:**
- Complete customer profile with all fields populated
- Personal details, address, PAN, etc.

### 6. Add Policy API

```bash
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "insurance_type": "health",
    "plan_name": "New Health Plan",
    "sum_insured": 500000,
    "premium_amount": 25000,
    "renewal_date": "2026-12-31",
    "policy_number": "TEST_NEW_001",
    "insurance_company": "Star Health",
    "remarks": "Customer requested policy"
  }' \
  "http://localhost:3000/api/v1/mobile/customer/add_policy"
```

## Issue Fixed: Upcoming Installments

### Problem
The `upcoming_installments` API was returning null/empty results because:
1. The API calculates "next installment date" by adding the payment period to `installment_autopay_start_date`
2. Our initial seed data set `installment_autopay_start_date` to future dates
3. Adding payment period to future dates resulted in dates >30 days away

### Solution
Updated the seed data to set `installment_autopay_start_date` to past dates:
- Health monthly policy: 25 days ago → next installment in 5 days
- Life monthly policy: 27 days ago → next installment in 3 days

### Key Learning
The `installment_autopay_start_date` field represents the **base date** from which to calculate the next installment, not the next due date itself.

## Test Data Summary

| Policy Type | Policy Number | Payment Mode | Next Action |
|-------------|---------------|--------------|-------------|
| Health | HLT_MONTHLY_* | Monthly | Installment due in 5 days |
| Life | LIF_MONTHLY_* | Monthly | Installment due in 3 days |
| Health | HLT_EXPIRING_* | Yearly | Renewal due in 15 days |
| Health | HLT_ACTIVE_* | Yearly | Active, no action needed |

## Ready for Testing! 🚀

All mobile APIs now have complete, realistic test data and are working correctly. The upcoming installments API specifically now returns proper data with installments due within the next 30 days.