# Mobile App API Documentation - Enhanced
## Dhanvantari Naturals - E-commerce Platform

---

## 🔐 **Authentication & Authorization**

### Base URL
```
Production: https://api.dhanvantrinaturals.com/api/v1/mobile
Development: http://localhost:3000/api/v1/mobile
```

### Headers
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json",
  "Authorization": "Bearer {token}"  // Required for authenticated endpoints
}
```

### Response Format
All API responses follow this standard format:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error message",
  "errors": { ... }  // Optional field-specific errors
}
```

---

## 📱 **1. AUTHENTICATION ENDPOINTS**

### **1.1 Customer Registration**
```http
POST /auth/register
```

**Request Body:**
```json
{
  "first_name": "string",
  "last_name": "string",
  "middle_name": "string",  // optional
  "email": "string",
  "mobile": "string",
  "password": "string",
  "password_confirmation": "string",
  "address": "string",
  "city": "string",
  "state": "string",
  "pincode": "string",
  "whatsapp_number": "string",  // optional
  "latitude": 19.0760,  // optional
  "longitude": 72.8777  // optional
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "email": "john@example.com",
      "mobile": "9876543210"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "customer_id": 123
  }
}
```

### **1.2 Customer/Agent Login**
```http
POST /auth/login
```

**Request Body:**
```json
{
  "username": "string",  // Email or mobile number
  "password": "string"
}
```

**Alternative Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Alternative Request Body:**
```json
{
  "mobile": "string",
  "password": "string"
}
```

**Response for Customer (200 OK):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "username": "John Doe",
    "role": "customer",
    "user_id": 1,
    "customer_id": 123,
    "email": "john@example.com",
    "mobile": "9876543210",
    "portfolio_summary": {
      "total_policies": 5,
      "upcoming_installments": 2,
      "renewal_policies": 1
    }
  }
}
```

**Response for Agent (200 OK):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "username": "Agent Name",
    "role": "agent",
    "user_id": 2,
    "email": "agent@example.com",
    "mobile": "9876543211",
    "commission_earned": 25000.00,
    "customers_count": 45,
    "policies_count": 120,
    "commission_breakdown": {
      "health": 10000,
      "life": 8000,
      "motor": 7000
    },
    "dashboard_stats": {
      "total_commission": 25000,
      "monthly_target": 75000,
      "achievement_percentage": 33.33,
      "policies_this_month": 36,
      "customers_this_month": 11,
      "conversion_rate": "75%"
    }
  }
}
```

### **1.3 Delivery Person Login**
```http
POST /auth/login
```
**Note:** Delivery persons use the same login endpoint but with delivery person credentials

**Request Body:**
```json
{
  "mobile": "string",
  "password": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "username": "Delivery Person Name",
    "role": "delivery_person",
    "user_id": 10,
    "delivery_person_id": 5,
    "mobile": "9876543210",
    "vehicle_type": "Two Wheeler",
    "vehicle_number": "KA-01-AB-1234",
    "profile_picture": "url_to_image",
    "status": "active"
  }
}
```

### **1.4 Forgot Password**
```http
POST /auth/forgot_password
```

**Request Body:**
```json
{
  "email_or_mobile": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset instructions sent",
  "data": {
    "reset_method": "email",  // or "sms"
    "sent_to": "j***@example.com"
  }
}
```

---

## 🛍️ **2. E-COMMERCE ENDPOINTS**

### **2.1 Get Categories**
```http
GET /ecommerce/categories
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Groceries",
      "description": "Daily grocery items",
      "image_url": "url_to_image",
      "products_count": 45,
      "display_order": 1
    },
    {
      "id": 2,
      "name": "Milk Products",
      "description": "Fresh dairy products",
      "image_url": "url_to_image",
      "products_count": 12,
      "display_order": 2
    }
  ],
  "message": "Categories retrieved successfully"
}
```

### **2.2 Get Category Details**
```http
GET /ecommerce/categories/{category_id}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Groceries",
    "description": "Daily grocery items",
    "image_url": "url_to_image",
    "products_count": 45,
    "display_order": 1
  },
  "message": "Category details retrieved successfully"
}
```

### **2.3 Get Products**
```http
GET /ecommerce/products
```

**Query Parameters:**
- `category_id` (integer): Filter by category
- `min_price` (decimal): Minimum price
- `max_price` (decimal): Maximum price
- `search` (string): Search term
- `sort_by` (string): price_low/price_high/name/newest/rating
- `page` (integer): Page number (default: 1)
- `per_page` (integer): Items per page (default: 20, max: 50)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": 1,
        "name": "Organic Rice",
        "description": "Premium quality organic rice",
        "category": {
          "id": 1,
          "name": "Groceries"
        },
        "price": 250.00,
        "discount_price": 225.00,
        "discount_percentage": 10,
        "images": {
          "main": "url_to_main_image",
          "additional": ["url1", "url2"]
        },
        "stock_status": "in_stock",
        "stock_quantity": 100,
        "unit": "Kg",
        "weight": "5",
        "product_type": "Grocery",
        "is_subscription_enabled": true,
        "is_occasional_product": false,
        "average_rating": 4.5,
        "reviews_count": 25,
        "gst_enabled": true,
        "gst_percentage": 5
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_count": 95,
      "total_pages": 5,
      "has_next_page": true,
      "has_prev_page": false
    },
    "applied_filters": {
      "category_id": null,
      "min_price": null,
      "max_price": null,
      "search": null,
      "sort_by": null
    }
  },
  "message": "Products retrieved successfully"
}
```

### **2.4 Get Products by Category**
```http
GET /ecommerce/categories/{category_id}/products
```

**Query Parameters:** Same as Get Products

**Response:** Similar to Get Products with additional category info

### **2.5 Get Product Details**
```http
GET /ecommerce/products/{product_id}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Organic Rice",
    "description": "Premium quality organic rice from certified farms",
    "category": {
      "id": 1,
      "name": "Groceries"
    },
    "price": 250.00,
    "discount_price": 225.00,
    "discount_percentage": 10,
    "images": {
      "main": "url_to_main_image",
      "additional": ["url1", "url2", "url3"]
    },
    "stock_status": "in_stock",
    "stock_quantity": 100,
    "weight": "5",
    "unit": "Kg",
    "dimensions": "30x20x10 cm",
    "product_type": "Grocery",
    "is_subscription_enabled": true,
    "subscription_frequencies": ["daily", "weekly", "monthly"],
    "is_occasional_product": false,
    "occasional_details": null,
    "nutritional_info": {
      "calories": "130 per 100g",
      "protein": "2.7g",
      "carbohydrates": "28g",
      "fat": "0.3g"
    },
    "average_rating": 4.5,
    "reviews_count": 25,
    "reviews": [
      {
        "id": 1,
        "rating": 5,
        "comment": "Excellent quality rice",
        "reviewer_name": "John D.",
        "created_at": "2024-01-15",
        "verified_purchase": true
      }
    ],
    "delivery_info": {
      "estimated_days": 2,
      "delivery_charge": 0,
      "free_delivery_above": 500
    },
    "gst_enabled": true,
    "gst_percentage": 5,
    "gst_amount": 11.25,
    "final_price": 236.25,
    "similar_products": [...]
  },
  "message": "Product details retrieved successfully"
}
```

### **2.6 Check Product Delivery Availability**
```http
POST /ecommerce/products/{product_id}/check_delivery
```

**Request Body:**
```json
{
  "pincode": "400001"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "deliverable": true,
    "estimated_days": 2,
    "delivery_charge": 50,
    "cod_available": true,
    "message": "Delivery available to this location"
  }
}
```

### **2.7 Search Products**
```http
GET /ecommerce/search
```

**Query Parameters:**
- `query` (string, required): Search term
- All other parameters same as Get Products

**Response:** Same as Get Products endpoint

### **2.8 Get Featured Products**
```http
GET /ecommerce/featured_products
```

**Response:** Similar to Get Products but returns featured items

### **2.9 Get Filters**
```http
GET /ecommerce/filters
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "categories": [...],
    "price_ranges": [
      { "min": 0, "max": 100, "label": "Under ₹100" },
      { "min": 100, "max": 500, "label": "₹100 - ₹500" }
    ],
    "product_types": ["Grocery", "Milk", "Fruit & Vegetable"],
    "units": ["Kg", "Liter", "Bottle", "Box"],
    "subscription_types": ["One Time", "Daily", "Weekly", "Monthly"],
    "ratings": [4, 3, 2, 1]
  }
}
```

---

## 🛒 **3. BOOKING/ORDER MANAGEMENT**

### **3.1 Create Booking (Place Order)**
```http
POST /ecommerce/bookings
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "booking": {
    "customer_name": "John Doe",
    "customer_email": "john@example.com",
    "customer_phone": "9876543210",
    "delivery_address": "123 Main St, Apartment 4B, Mumbai",
    "pincode": "400001",
    "latitude": 19.0760,  // optional
    "longitude": 72.8777,  // optional
    "payment_method": "cod",  // cod/online/upi
    "notes": "Please call before delivery",
    "booking_items_attributes": [
      {
        "product_id": 1,
        "quantity": 2,
        "price": 225.00
      },
      {
        "product_id": 3,
        "quantity": 1,
        "price": 150.00
      }
    ]
  }
}
```

**Note:** Cart is managed on frontend. When placing order, send all cart items in `booking_items_attributes`.

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "booking": {
      "id": 101,
      "booking_number": "BKG-2024-0101",
      "booking_date": "2024-01-20T10:30:00Z",
      "status": "confirmed",
      "payment_method": "cod",
      "payment_status": "pending",
      "items": [
        {
          "product_id": 1,
          "product_name": "Organic Rice",
          "quantity": 2,
          "price": 225.00,
          "total": 450.00
        }
      ],
      "price_summary": {
        "subtotal": 600.00,
        "delivery_charge": 50.00,
        "discount": 0,
        "tax": 32.50,
        "total": 682.50
      },
      "delivery_details": {
        "address": "123 Main St, Apartment 4B, Mumbai",
        "pincode": "400001",
        "estimated_delivery": "2024-01-22",
        "delivery_slot": "10:00 AM - 12:00 PM"
      }
    }
  }
}
```

### **3.2 Get My Bookings**
```http
GET /ecommerce/bookings
```

**Headers Required:** Authorization

**Query Parameters:**
- `status` (string): pending/confirmed/processing/delivered/cancelled
- `from_date` (date): Start date
- `to_date` (date): End date
- `page` (integer): Page number
- `per_page` (integer): Items per page

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "bookings": [
      {
        "id": 101,
        "booking_number": "BKG-2024-0101",
        "booking_date": "2024-01-20T10:30:00Z",
        "status": "delivered",
        "payment_status": "paid",
        "total_amount": 682.50,
        "items_count": 2,
        "delivery_date": "2024-01-22"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 48
    }
  },
  "message": "Bookings retrieved successfully"
}
```

### **3.3 Get Order List**
```http
GET /ecommerce/orders
```

**Headers Required:** Authorization

**Query Parameters:** Same as Get My Bookings

**Response:** Similar structure to bookings

### **3.4 Get Order Details**
```http
GET /ecommerce/orders/{order_id}
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "order": {
      "id": 101,
      "order_number": "ORD-2024-0101",
      "booking_id": 101,
      "order_date": "2024-01-20T10:30:00Z",
      "status": "out_for_delivery",
      "status_history": [
        {
          "status": "placed",
          "timestamp": "2024-01-20T10:30:00Z",
          "message": "Order placed successfully"
        },
        {
          "status": "confirmed",
          "timestamp": "2024-01-20T10:35:00Z",
          "message": "Order confirmed"
        },
        {
          "status": "out_for_delivery",
          "timestamp": "2024-01-22T08:00:00Z",
          "message": "Out for delivery"
        }
      ],
      "items": [
        {
          "product_id": 1,
          "product_name": "Organic Rice",
          "quantity": 2,
          "price": 225.00,
          "total": 450.00,
          "image": "url_to_image"
        }
      ],
      "delivery_person": {
        "id": 5,
        "name": "Delivery Person Name",
        "mobile": "9876543210",
        "vehicle_number": "KA-01-AB-1234"
      },
      "payment": {
        "method": "cod",
        "status": "pending",
        "amount": 682.50
      },
      "delivery": {
        "address": "123 Main St, Apartment 4B, Mumbai",
        "pincode": "400001",
        "estimated_date": "2024-01-22",
        "estimated_time": "10:00 AM - 12:00 PM",
        "tracking_available": true
      },
      "invoice": {
        "available": true,
        "download_url": "/api/v1/mobile/invoices/45/download"
      }
    }
  },
  "message": "Order details retrieved successfully"
}
```

---

## 📅 **4. SUBSCRIPTION MANAGEMENT**

### **4.1 Create Subscription**
```http
POST /ecommerce/subscriptions
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "subscription": {
    "product_id": 1,
    "quantity": 2,
    "frequency": "daily",  // daily/weekly/monthly
    "start_date": "2024-01-25",
    "end_date": "2024-02-25",  // optional
    "delivery_time": "morning",  // morning/afternoon/evening
    "delivery_address": "123 Main St, Mumbai",
    "pincode": "400001",
    "special_instructions": "Ring doorbell twice"
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Subscription created successfully",
  "data": {
    "subscription": {
      "id": 10,
      "product": {
        "id": 1,
        "name": "Organic Milk",
        "image": "url_to_image"
      },
      "quantity": 2,
      "frequency": "daily",
      "start_date": "2024-01-25",
      "end_date": "2024-02-25",
      "next_delivery": "2024-01-25",
      "delivery_time": "morning",
      "status": "active",
      "price_per_delivery": 60.00,
      "total_deliveries_scheduled": 32
    }
  }
}
```

### **4.2 Get My Subscriptions**
```http
GET /ecommerce/subscriptions
```

**Headers Required:** Authorization

**Query Parameters:**
- `status` (string): active/paused/cancelled/expired
- `page` (integer): Page number
- `per_page` (integer): Items per page

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "subscriptions": [
      {
        "id": 10,
        "product": {
          "id": 1,
          "name": "Organic Milk",
          "image": "url_to_image"
        },
        "quantity": 2,
        "frequency": "daily",
        "next_delivery": "2024-01-25",
        "delivery_time": "morning",
        "status": "active",
        "price_per_delivery": 60.00,
        "deliveries_completed": 5,
        "total_amount_spent": 300.00
      }
    ],
    "summary": {
      "active_subscriptions": 3,
      "paused_subscriptions": 1,
      "total_monthly_value": 1800.00,
      "next_delivery_date": "2024-01-25"
    },
    "pagination": {
      "current_page": 1,
      "total_pages": 1,
      "total_count": 4
    }
  },
  "message": "Subscriptions retrieved successfully"
}
```

### **4.3 Get Subscription Details**
```http
GET /ecommerce/subscriptions/{subscription_id}
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "id": 10,
      "product": {
        "id": 1,
        "name": "Organic Milk",
        "description": "Fresh organic milk",
        "image": "url_to_image",
        "price": 30.00,
        "unit": "Liter"
      },
      "quantity": 2,
      "frequency": "daily",
      "start_date": "2024-01-20",
      "end_date": "2024-02-20",
      "next_delivery": "2024-01-25",
      "delivery_time": "morning",
      "delivery_address": "123 Main St, Mumbai",
      "status": "active",
      "price_per_delivery": 60.00,
      "deliveries_completed": 5,
      "deliveries_remaining": 27,
      "delivery_history": [
        {
          "date": "2024-01-24",
          "status": "delivered",
          "quantity": 2,
          "amount": 60.00
        },
        {
          "date": "2024-01-23",
          "status": "delivered",
          "quantity": 2,
          "amount": 60.00
        }
      ],
      "upcoming_deliveries": [
        {
          "date": "2024-01-25",
          "day": "Thursday",
          "estimated_time": "7:00 AM - 8:00 AM"
        }
      ],
      "pause_history": [],
      "modification_history": [],
      "statistics": {
        "total_deliveries": 5,
        "successful_deliveries": 5,
        "failed_deliveries": 0,
        "total_amount_spent": 300.00,
        "average_rating": 4.8
      }
    }
  },
  "message": "Subscription details retrieved successfully"
}
```

### **4.4 Pause Subscription**
```http
PUT /ecommerce/subscriptions/{subscription_id}/pause
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "pause_from": "2024-01-26",
  "pause_until": "2024-02-01",
  "reason": "Out of town"  // optional
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Subscription paused successfully",
  "data": {
    "subscription_id": 10,
    "status": "paused",
    "pause_from": "2024-01-26",
    "pause_until": "2024-02-01",
    "will_resume_on": "2024-02-02"
  }
}
```

### **4.5 Resume Subscription**
```http
PUT /ecommerce/subscriptions/{subscription_id}/resume
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "resume_date": "2024-01-30"  // optional, immediate if not provided
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Subscription resumed successfully",
  "data": {
    "subscription_id": 10,
    "status": "active",
    "next_delivery": "2024-01-30"
  }
}
```

---

## 🚚 **5. DELIVERY PERSON ENDPOINTS**

### **5.1 Delivery Person Authentication**

Delivery persons should use the regular login endpoint (`/auth/login`) with their mobile number and password. The system will automatically detect they are delivery personnel and return appropriate data.

### **5.2 Get Today's Deliveries**
```http
GET /delivery/tasks/today
```

**Headers Required:** Authorization (Delivery Person Token)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_tasks": 15,
      "completed": 8,
      "pending": 7,
      "failed": 0,
      "total_collection": 2500.00
    },
    "tasks": [
      {
        "id": 201,
        "type": "order",  // order/subscription
        "order_number": "ORD-2024-0201",
        "customer": {
          "name": "John Doe",
          "mobile": "9876543210",
          "address": "123 Main St, Apartment 4B",
          "landmark": "Near City Mall",
          "pincode": "400001",
          "latitude": 19.0760,
          "longitude": 72.8777
        },
        "items": [
          {
            "product_name": "Organic Rice",
            "quantity": 2,
            "unit": "Kg"
          }
        ],
        "payment": {
          "method": "cod",
          "amount_to_collect": 682.50,
          "status": "pending"
        },
        "delivery_slot": "10:00 AM - 12:00 PM",
        "priority": "normal",  // high/normal/low
        "status": "pending",
        "special_instructions": "Call before delivery"
      }
    ],
    "route_optimization": {
      "suggested_sequence": [201, 203, 205],
      "estimated_completion_time": "4 hours",
      "total_distance": "25 km"
    }
  }
}
```

### **5.3 Get Task Details**
```http
GET /delivery/tasks/{task_id}
```

**Headers Required:** Authorization (Delivery Person Token)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "task": {
      "id": 201,
      "type": "order",
      "order_number": "ORD-2024-0201",
      "customer": {
        "name": "John Doe",
        "mobile": "9876543210",
        "alternate_mobile": "9876543211",
        "address": "123 Main St, Apartment 4B, Mumbai",
        "landmark": "Near City Mall",
        "pincode": "400001",
        "location": {
          "latitude": 19.0760,
          "longitude": 72.8777
        }
      },
      "items": [
        {
          "product_id": 1,
          "product_name": "Organic Rice",
          "quantity": 2,
          "unit": "Kg",
          "price": 225.00
        }
      ],
      "payment": {
        "method": "cod",
        "total_amount": 682.50,
        "amount_to_collect": 682.50,
        "status": "pending"
      },
      "delivery_attempts": [],
      "status": "pending",
      "special_instructions": "Call before delivery",
      "customer_preference": {
        "preferred_time": "10:00 AM - 12:00 PM",
        "contact_before_delivery": true
      }
    }
  }
}
```

### **5.4 Start Delivery Task**
```http
POST /delivery/tasks/{task_id}/start
```

**Headers Required:** Authorization (Delivery Person Token)

**Request Body:**
```json
{
  "start_location": {
    "latitude": 19.0750,
    "longitude": 72.8775
  },
  "estimated_arrival_minutes": 15
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Delivery started",
  "data": {
    "task_id": 201,
    "status": "in_progress",
    "started_at": "2024-01-22T09:45:00Z",
    "estimated_arrival": "10:00 AM"
  }
}
```

### **5.5 Complete Delivery**
```http
POST /delivery/tasks/{task_id}/complete
```

**Headers Required:** Authorization (Delivery Person Token)

**Request Body:**
```json
{
  "delivery_proof": {
    "recipient_name": "John Doe",
    "signature": "base64_encoded_signature_image",  // optional
    "photo": "base64_encoded_delivery_photo",  // optional
    "otp": "1234"  // if OTP verification enabled
  },
  "payment_collected": {
    "amount": 682.50,
    "method": "cash"  // cash/upi/card
  },
  "location": {
    "latitude": 19.0760,
    "longitude": 72.8777
  },
  "notes": "Delivered successfully to customer"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Delivery completed successfully",
  "data": {
    "task_id": 201,
    "status": "completed",
    "completed_at": "2024-01-22T10:15:00Z",
    "payment_status": "collected",
    "next_task_id": 203  // optional, next task in route
  }
}
```

### **5.6 Mark Delivery Failed**
```http
POST /delivery/tasks/{task_id}/fail
```

**Headers Required:** Authorization (Delivery Person Token)

**Request Body:**
```json
{
  "reason": "customer_not_available",  // customer_not_available/wrong_address/refused/other
  "attempted_at": "2024-01-22T10:00:00Z",
  "location": {
    "latitude": 19.0760,
    "longitude": 72.8777
  },
  "notes": "Rang doorbell multiple times, no response",
  "reschedule": {
    "requested": true,
    "preferred_date": "2024-01-23",
    "preferred_time": "afternoon"
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Delivery marked as failed",
  "data": {
    "task_id": 201,
    "status": "failed",
    "reason": "customer_not_available",
    "next_attempt_scheduled": "2024-01-23",
    "attempt_number": 1
  }
}
```

### **5.7 Update Delivery Location**
```http
POST /delivery/tasks/{task_id}/update_location
```

**Headers Required:** Authorization (Delivery Person Token)

**Request Body:**
```json
{
  "latitude": 19.0755,
  "longitude": 72.8776,
  "timestamp": "2024-01-22T09:50:00Z"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Location updated",
  "data": {
    "distance_to_customer": "500 meters",
    "estimated_arrival": "5 minutes"
  }
}
```

### **5.8 Get Delivery Statistics**
```http
GET /delivery/statistics
```

**Headers Required:** Authorization (Delivery Person Token)

**Query Parameters:**
- `period` (string): today/week/month

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "period": "today",
    "statistics": {
      "total_deliveries": 15,
      "completed": 8,
      "failed": 1,
      "pending": 6,
      "success_rate": 88.89,
      "total_distance": "45 km",
      "total_collection": 5420.00,
      "average_delivery_time": "18 minutes",
      "customer_ratings": {
        "average": 4.7,
        "total_ratings": 8
      }
    }
  }
}
```

---

## 📍 **6. DELIVERY VALIDATION ENDPOINTS**

### **6.1 Check Product Delivery**
```http
POST /api/delivery/check_product_delivery
```

**Request Body:**
```json
{
  "product_id": 1,
  "pincode": "400001"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "deliverable": true,
  "estimated_days": 2,
  "delivery_charge": 0,
  "message": "Delivery available"
}
```

### **6.2 Check Cart Delivery**
```http
POST /api/delivery/check_cart_delivery
```

**Request Body:**
```json
{
  "cart_items": [
    {
      "product_id": 1,
      "quantity": 2
    },
    {
      "product_id": 3,
      "quantity": 1
    }
  ],
  "pincode": "400001"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "all_deliverable": true,
  "undeliverable_products": [],
  "total_delivery_charge": 50,
  "estimated_delivery_days": 2,
  "message": "All products can be delivered"
}
```

---

## 🔧 **7. UTILITY ENDPOINTS**

### **7.1 Get App Settings**
```http
GET /settings/app_config
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "app_version": {
      "minimum_version": "1.0.0",
      "current_version": "1.2.0",
      "force_update": false
    },
    "payment_methods": ["cod", "upi", "card", "wallet"],
    "delivery_slots": [
      "Morning (7 AM - 10 AM)",
      "Afternoon (12 PM - 3 PM)",
      "Evening (5 PM - 8 PM)"
    ],
    "support": {
      "phone": "+91 98765 43210",
      "email": "support@dhanvantrinaturals.com",
      "whatsapp": "+91 98765 43210"
    },
    "business_hours": {
      "monday_friday": "9:00 AM - 7:00 PM",
      "saturday": "9:00 AM - 5:00 PM",
      "sunday": "Closed"
    },
    "policies": {
      "return_days": 7,
      "minimum_order_value": 100,
      "free_delivery_above": 500
    }
  }
}
```

### **7.2 Validate Pincode**
```http
GET /settings/validate_pincode/{pincode}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "pincode": "400001",
    "city": "Mumbai",
    "state": "Maharashtra",
    "delivery_available": true,
    "estimated_days": 2,
    "cod_available": true
  }
}
```

---

## ❌ **ERROR RESPONSES**

All error responses follow this format:

### **400 Bad Request**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["is invalid"],
    "mobile": ["is already taken"]
  }
}
```

### **401 Unauthorized**
```json
{
  "success": false,
  "message": "Unauthorized access"
}
```

### **403 Forbidden**
```json
{
  "success": false,
  "message": "You don't have permission to access this resource"
}
```

### **404 Not Found**
```json
{
  "success": false,
  "message": "Resource not found"
}
```

### **422 Unprocessable Entity**
```json
{
  "success": false,
  "message": "Unable to process request",
  "errors": {
    "field_name": ["error message"]
  }
}
```

### **500 Internal Server Error**
```json
{
  "success": false,
  "message": "Internal server error. Please try again later."
}
```

---

## 🔑 **AUTHENTICATION NOTES**

1. **Token Management:**
   - Tokens expire after 24 hours
   - Include token in Authorization header: `Bearer {token}`
   - Refresh token before expiry to maintain session

2. **User Roles:**
   - `customer`: Regular app users who can browse, order, subscribe
   - `agent`: Sales agents with limited admin access
   - `delivery_person`: Delivery personnel with access to delivery tasks
   - `admin`: Full system access (not for mobile app)

3. **Security Best Practices:**
   - Always use HTTPS in production
   - Store tokens securely in mobile app
   - Implement biometric authentication where available
   - Clear tokens on logout

---

## 📦 **CART MANAGEMENT NOTES**

Cart is managed entirely on the frontend/mobile app side:

1. **Frontend Responsibilities:**
   - Store cart items in local storage/state
   - Calculate cart totals
   - Validate stock availability before checkout
   - Sync cart across app sessions if needed

2. **When Placing Order:**
   - Send complete cart items array in `booking_items_attributes`
   - Backend validates stock and prices
   - Backend calculates final totals with taxes
   - Returns error if any item is out of stock

3. **Cart Validation:**
   - Use `/api/delivery/check_cart_delivery` to validate delivery
   - Check product availability before checkout
   - Handle out-of-stock scenarios gracefully

---

## 📱 **MOBILE APP IMPLEMENTATION TIPS**

1. **Offline Support:**
   - Cache product catalog for offline browsing
   - Queue orders when offline and sync when online
   - Store user preferences locally

2. **Performance:**
   - Implement pagination for all list endpoints
   - Use image caching for product images
   - Lazy load product details

3. **User Experience:**
   - Show loading states for all API calls
   - Implement pull-to-refresh on list screens
   - Handle errors gracefully with user-friendly messages

4. **Notifications:**
   - Register device token for push notifications
   - Handle delivery updates via push
   - Show in-app notifications for order status changes

---

## 📄 **CHANGELOG**

### Version 1.2.0 (Current)
- Enhanced authentication flow for delivery persons
- Added comprehensive order placement with cart items
- Improved delivery person task management
- Added delivery validation endpoints
- Added location tracking for delivery persons

### Version 1.1.0
- Added subscription management
- Enhanced product filtering
- Added delivery slot selection

### Version 1.0.0
- Initial API release
- Basic authentication and product browsing
- Order placement and tracking