# Mobile App API Documentation
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
  "device_token": "string"  // For push notifications
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
    "refresh_token": "refresh_token_string"
  }
}
```

### **1.2 Customer Login**
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email_or_mobile": "string",  // Email or mobile number
  "password": "string",
  "device_token": "string"  // For push notifications
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "email": "john@example.com",
      "mobile": "9876543210",
      "profile_picture": "url_to_image"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "refresh_token_string"
  }
}
```

### **1.3 Delivery Person Login**
```http
POST /delivery/auth/login
```

**Request Body:**
```json
{
  "mobile": "string",
  "password": "string",
  "device_token": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "delivery_person": {
      "id": 1,
      "first_name": "Driver",
      "last_name": "Name",
      "mobile": "9876543210",
      "vehicle_number": "KA-01-AB-1234",
      "profile_picture": "url_to_image"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### **1.4 Logout**
```http
POST /auth/logout
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### **1.5 Refresh Token**
```http
POST /auth/refresh
```

**Request Body:**
```json
{
  "refresh_token": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "token": "new_jwt_token",
    "refresh_token": "new_refresh_token"
  }
}
```

### **1.6 Forgot Password**
```http
POST /auth/forgot-password
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
  "message": "OTP sent successfully",
  "data": {
    "otp_sent_to": "98765*****",
    "expires_in": 300  // seconds
  }
}
```

### **1.7 Verify OTP**
```http
POST /auth/verify-otp
```

**Request Body:**
```json
{
  "email_or_mobile": "string",
  "otp": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "reset_token": "token_for_password_reset"
  }
}
```

### **1.8 Reset Password**
```http
POST /auth/reset-password
```

**Request Body:**
```json
{
  "reset_token": "string",
  "new_password": "string",
  "password_confirmation": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

## 🏠 **2. HOME & DISCOVERY ENDPOINTS**

### **2.1 Home Page Data**
```http
GET /home
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "banners": [
      {
        "id": 1,
        "title": "Special Offer",
        "description": "Get 20% off on organic spices",
        "image_url": "url_to_image",
        "redirect_link": "/category/spices",
        "display_order": 1
      }
    ],
    "categories": [
      {
        "id": 1,
        "name": "Groceries",
        "image": "url_to_image",
        "products_count": 45
      }
    ],
    "featured_products": [
      {
        "id": 1,
        "name": "Organic Rice",
        "price": 250.00,
        "discount_price": 225.00,
        "image": "url_to_image",
        "in_stock": true,
        "is_subscription_enabled": true
      }
    ],
    "trending_products": [...],
    "seasonal_products": [
      {
        "id": 5,
        "name": "Seasonal Mangoes",
        "price": 150.00,
        "image": "url_to_image",
        "availability": {
          "type": "occasional",
          "available_from": "2024-04-01",
          "available_to": "2024-06-30"
        }
      }
    ],
    "active_subscriptions_count": 3,
    "cart_items_count": 5
  }
}
```

### **2.2 Search Products**
```http
GET /search
```

**Query Parameters:**
- `query` (string, required): Search term
- `category_id` (integer): Filter by category
- `min_price` (decimal): Minimum price
- `max_price` (decimal): Maximum price
- `in_stock` (boolean): Only show in-stock items
- `product_type` (string): regular/occasional/subscription
- `sort_by` (string): price_asc/price_desc/name/popularity
- `page` (integer): Page number (default: 1)
- `limit` (integer): Items per page (default: 20)

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
        "price": 250.00,
        "discount_price": 225.00,
        "image": "url_to_image",
        "in_stock": true,
        "stock_quantity": 100,
        "is_subscription_enabled": true
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 95,
      "items_per_page": 20
    }
  }
}
```

---

## 🛍️ **3. PRODUCT ENDPOINTS**

### **3.1 Get Categories**
```http
GET /categories
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": 1,
        "name": "Groceries",
        "description": "Daily grocery items",
        "image": "url_to_image",
        "products_count": 45,
        "display_order": 1
      }
    ]
  }
}
```

### **3.2 Get Products by Category**
```http
GET /categories/{category_id}/products
```

**Query Parameters:**
- Similar to search endpoint

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "category": {
      "id": 1,
      "name": "Groceries"
    },
    "products": [...],
    "pagination": {...}
  }
}
```

### **3.3 Get Product Details**
```http
GET /products/{product_id}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "product": {
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
      "images": [
        "url_to_image_1",
        "url_to_image_2"
      ],
      "in_stock": true,
      "stock_quantity": 100,
      "weight": "5 kg",
      "dimensions": "30x20x10 cm",
      "nutritional_info": {
        "calories": "130 per 100g",
        "protein": "2.7g",
        "carbohydrates": "28g"
      },
      "is_subscription_enabled": true,
      "subscription_options": {
        "frequencies": ["daily", "weekly", "monthly"],
        "discount_percentage": 5
      },
      "product_type": "regular",  // regular/occasional
      "occasional_schedule": null,
      "reviews_count": 25,
      "average_rating": 4.5,
      "gst_enabled": true,
      "gst_percentage": 5
    }
  }
}
```

### **3.4 Get Product Reviews**
```http
GET /products/{product_id}/reviews
```

**Query Parameters:**
- `page` (integer): Page number
- `limit` (integer): Items per page

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "id": 1,
        "rating": 5,
        "comment": "Excellent quality rice",
        "reviewer_name": "John D.",
        "created_at": "2024-01-15T10:30:00Z",
        "verified_purchase": true,
        "helpful_count": 12
      }
    ],
    "summary": {
      "average_rating": 4.5,
      "total_reviews": 25,
      "rating_distribution": {
        "5": 15,
        "4": 7,
        "3": 2,
        "2": 1,
        "1": 0
      }
    },
    "pagination": {...}
  }
}
```

### **3.5 Submit Product Review**
```http
POST /products/{product_id}/reviews
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "rating": 5,
  "comment": "Excellent quality product"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Review submitted successfully",
  "data": {
    "review_id": 26
  }
}
```

---

## 🛒 **4. CART ENDPOINTS**

### **4.1 Get Cart**
```http
GET /cart
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "cart": {
      "id": 1,
      "items": [
        {
          "id": 1,
          "product_id": 1,
          "product_name": "Organic Rice",
          "product_image": "url_to_image",
          "price": 250.00,
          "discount_price": 225.00,
          "quantity": 2,
          "subtotal": 450.00,
          "in_stock": true
        }
      ],
      "summary": {
        "subtotal": 900.00,
        "discount": 50.00,
        "gst": 45.00,
        "delivery_charge": 40.00,
        "total": 935.00
      },
      "items_count": 3
    }
  }
}
```

### **4.2 Add to Cart**
```http
POST /cart/items
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 2,
  "is_subscription": false
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Product added to cart",
  "data": {
    "cart_item_id": 5,
    "cart_items_count": 4
  }
}
```

### **4.3 Update Cart Item**
```http
PUT /cart/items/{item_id}
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "quantity": 3
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Cart item updated",
  "data": {
    "updated_subtotal": 675.00,
    "cart_summary": {...}
  }
}
```

### **4.4 Remove from Cart**
```http
DELETE /cart/items/{item_id}
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Item removed from cart",
  "data": {
    "cart_items_count": 3
  }
}
```

### **4.5 Clear Cart**
```http
DELETE /cart/clear
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Cart cleared successfully"
}
```

---

## 💳 **5. CHECKOUT & ORDER ENDPOINTS**

### **5.1 Checkout Summary**
```http
POST /checkout/summary
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "delivery_address_id": 1,
  "coupon_code": "SAVE10"  // optional
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [...],
    "delivery_address": {
      "id": 1,
      "name": "John Doe",
      "address": "123 Main St",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400001",
      "mobile": "9876543210"
    },
    "price_breakdown": {
      "subtotal": 900.00,
      "discount": 90.00,
      "coupon_discount": 50.00,
      "gst": 43.00,
      "cgst": 21.50,
      "sgst": 21.50,
      "delivery_charge": 40.00,
      "total": 843.00,
      "savings": 140.00
    },
    "payment_methods": [
      {
        "id": "cod",
        "name": "Cash on Delivery",
        "available": true
      }
    ],
    "estimated_delivery": "2024-01-20"
  }
}
```

### **5.2 Place Order**
```http
POST /orders/create
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "delivery_address_id": 1,
  "payment_method": "cod",
  "coupon_code": "SAVE10",  // optional
  "delivery_instructions": "Call before delivery",  // optional
  "preferred_delivery_time": "morning"  // morning/afternoon/evening
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Order placed successfully",
  "data": {
    "order": {
      "id": 101,
      "order_number": "ORD-2024-0101",
      "total_amount": 843.00,
      "payment_method": "cod",
      "status": "confirmed",
      "estimated_delivery": "2024-01-20",
      "tracking_url": "/orders/101/track"
    }
  }
}
```

### **5.3 Get Order Details**
```http
GET /orders/{order_id}
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
      "order_date": "2024-01-18T10:30:00Z",
      "status": "shipped",
      "status_history": [
        {
          "status": "placed",
          "timestamp": "2024-01-18T10:30:00Z"
        },
        {
          "status": "confirmed",
          "timestamp": "2024-01-18T10:35:00Z"
        },
        {
          "status": "shipped",
          "timestamp": "2024-01-19T08:00:00Z"
        }
      ],
      "items": [
        {
          "product_id": 1,
          "product_name": "Organic Rice",
          "quantity": 2,
          "price": 225.00,
          "subtotal": 450.00,
          "image": "url_to_image"
        }
      ],
      "delivery_address": {...},
      "payment": {
        "method": "cod",
        "status": "pending",
        "amount": 843.00
      },
      "price_breakdown": {...},
      "delivery": {
        "estimated_date": "2024-01-20",
        "delivery_person": {
          "id": 5,
          "name": "Driver Name",
          "mobile": "9876543210",
          "vehicle_number": "KA-01-AB-1234"
        },
        "tracking": {
          "current_status": "out_for_delivery",
          "last_update": "2024-01-20T09:00:00Z"
        }
      },
      "invoice": {
        "id": 45,
        "invoice_number": "INV-2024-0045",
        "download_url": "/invoices/45/download"
      }
    }
  }
}
```

### **5.4 Get Order List**
```http
GET /orders
```

**Headers Required:** Authorization

**Query Parameters:**
- `status` (string): pending/confirmed/shipped/delivered/cancelled
- `page` (integer): Page number
- `limit` (integer): Items per page

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": 101,
        "order_number": "ORD-2024-0101",
        "order_date": "2024-01-18T10:30:00Z",
        "total_amount": 843.00,
        "status": "delivered",
        "items_count": 3,
        "first_item_image": "url_to_image"
      }
    ],
    "pagination": {...}
  }
}
```

### **5.5 Track Order**
```http
GET /orders/{order_id}/track
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "order_number": "ORD-2024-0101",
    "current_status": "out_for_delivery",
    "delivery_person": {
      "name": "Driver Name",
      "mobile": "9876543210",
      "location": {
        "latitude": 19.0760,
        "longitude": 72.8777
      }
    },
    "tracking_history": [
      {
        "status": "placed",
        "message": "Order placed successfully",
        "timestamp": "2024-01-18T10:30:00Z"
      },
      {
        "status": "out_for_delivery",
        "message": "Your order is out for delivery",
        "timestamp": "2024-01-20T09:00:00Z"
      }
    ],
    "estimated_delivery_time": "10:30 AM - 11:00 AM"
  }
}
```

### **5.6 Cancel Order**
```http
POST /orders/{order_id}/cancel
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "reason": "Changed my mind",
  "comments": "Optional additional comments"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Order cancelled successfully",
  "data": {
    "refund_status": "processing",
    "refund_amount": 843.00
  }
}
```

---

## 📅 **6. SUBSCRIPTION ENDPOINTS**

### **6.1 Get Subscription Plans**
```http
GET /subscriptions/plans
```

**Query Parameters:**
- `product_id` (integer): Get plans for specific product

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "plans": [
      {
        "id": 1,
        "name": "Daily Milk Subscription",
        "frequency": "daily",
        "discount_percentage": 5,
        "minimum_duration_days": 30,
        "benefits": [
          "5% discount on MRP",
          "Free delivery",
          "Pause anytime"
        ]
      },
      {
        "id": 2,
        "name": "Weekly Groceries",
        "frequency": "weekly",
        "discount_percentage": 7,
        "minimum_duration_days": 30
      }
    ]
  }
}
```

### **6.2 Create Subscription**
```http
POST /subscriptions/create
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 2,
  "frequency": "daily",  // daily/weekly/monthly
  "start_date": "2024-01-20",
  "delivery_time": "morning",  // morning/afternoon/evening
  "delivery_address_id": 1,
  "auto_renew": true
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
        "name": "Organic Milk"
      },
      "quantity": 2,
      "frequency": "daily",
      "start_date": "2024-01-20",
      "next_delivery": "2024-01-20",
      "delivery_time": "morning",
      "status": "active",
      "price_per_delivery": 60.00
    }
  }
}
```

### **6.3 Get My Subscriptions**
```http
GET /subscriptions
```

**Headers Required:** Authorization

**Query Parameters:**
- `status` (string): active/paused/cancelled
- `page` (integer): Page number
- `limit` (integer): Items per page

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
        "next_delivery": "2024-01-20",
        "delivery_time": "morning",
        "status": "active",
        "price_per_delivery": 60.00,
        "total_deliveries": 15,
        "total_amount_saved": 45.00
      }
    ],
    "summary": {
      "active_subscriptions": 3,
      "total_monthly_value": 1800.00,
      "total_savings": 135.00
    },
    "pagination": {...}
  }
}
```

### **6.4 Get Subscription Details**
```http
GET /subscriptions/{subscription_id}
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "id": 10,
      "product": {...},
      "quantity": 2,
      "frequency": "daily",
      "start_date": "2024-01-05",
      "next_delivery": "2024-01-20",
      "delivery_time": "morning",
      "delivery_address": {...},
      "status": "active",
      "price_per_delivery": 60.00,
      "delivery_history": [
        {
          "date": "2024-01-19",
          "status": "delivered",
          "amount": 60.00
        }
      ],
      "upcoming_deliveries": [
        {
          "date": "2024-01-20",
          "day": "Saturday",
          "estimated_time": "7:00 AM - 8:00 AM"
        }
      ],
      "statistics": {
        "total_deliveries": 15,
        "successful_deliveries": 14,
        "failed_deliveries": 1,
        "total_amount_spent": 900.00,
        "amount_saved": 45.00
      }
    }
  }
}
```

### **6.5 Update Subscription**
```http
PUT /subscriptions/{subscription_id}
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "quantity": 3,
  "delivery_time": "evening",
  "delivery_address_id": 2
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Subscription updated successfully",
  "data": {
    "changes_effective_from": "2024-01-21"
  }
}
```

### **6.6 Pause Subscription**
```http
POST /subscriptions/{subscription_id}/pause
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "pause_from": "2024-01-25",
  "pause_until": "2024-02-01",  // optional
  "reason": "Out of town"  // optional
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Subscription paused successfully",
  "data": {
    "pause_from": "2024-01-25",
    "pause_until": "2024-02-01",
    "resume_date": "2024-02-02"
  }
}
```

### **6.7 Resume Subscription**
```http
POST /subscriptions/{subscription_id}/resume
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
    "next_delivery": "2024-01-30"
  }
}
```

### **6.8 Skip Delivery**
```http
POST /subscriptions/{subscription_id}/skip
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "dates": ["2024-01-25", "2024-01-26"],
  "reason": "Not required"  // optional
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Deliveries skipped successfully",
  "data": {
    "skipped_dates": ["2024-01-25", "2024-01-26"],
    "next_delivery": "2024-01-27"
  }
}
```

### **6.9 Cancel Subscription**
```http
POST /subscriptions/{subscription_id}/cancel
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "reason": "No longer needed",
  "feedback": "Optional feedback"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Subscription cancelled successfully",
  "data": {
    "last_delivery_date": "2024-01-24",
    "refund_amount": 0
  }
}
```

---

## 👤 **7. USER PROFILE ENDPOINTS**

### **7.1 Get Profile**
```http
GET /profile
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "middle_name": "M",
      "email": "john@example.com",
      "mobile": "9876543210",
      "whatsapp_number": "9876543210",
      "profile_picture": "url_to_image",
      "created_at": "2024-01-01T00:00:00Z",
      "addresses": [
        {
          "id": 1,
          "type": "home",
          "address": "123 Main St",
          "city": "Mumbai",
          "state": "Maharashtra",
          "pincode": "400001",
          "is_default": true
        }
      ],
      "statistics": {
        "total_orders": 25,
        "active_subscriptions": 3,
        "total_savings": 450.00,
        "member_since_days": 30
      }
    }
  }
}
```

### **7.2 Update Profile**
```http
PUT /profile
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "whatsapp_number": "9876543210"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile updated successfully"
}
```

### **7.3 Upload Profile Picture**
```http
POST /profile/picture
```

**Headers Required:** Authorization

**Request Body (multipart/form-data):**
- `image`: File upload

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile picture updated successfully",
  "data": {
    "profile_picture_url": "url_to_new_image"
  }
}
```

### **7.4 Change Password**
```http
POST /profile/change-password
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "current_password": "string",
  "new_password": "string",
  "password_confirmation": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## 📍 **8. ADDRESS ENDPOINTS**

### **8.1 Get Addresses**
```http
GET /addresses
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "addresses": [
      {
        "id": 1,
        "type": "home",
        "name": "John Doe",
        "mobile": "9876543210",
        "address": "123 Main St",
        "landmark": "Near Park",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001",
        "latitude": 19.0760,
        "longitude": 72.8777,
        "is_default": true
      }
    ]
  }
}
```

### **8.2 Add Address**
```http
POST /addresses
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "type": "home",  // home/work/other
  "name": "John Doe",
  "mobile": "9876543210",
  "address": "123 Main St",
  "landmark": "Near Park",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "latitude": 19.0760,  // optional
  "longitude": 72.8777,  // optional
  "is_default": false
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Address added successfully",
  "data": {
    "address_id": 2
  }
}
```

### **8.3 Update Address**
```http
PUT /addresses/{address_id}
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "address": "456 New St",
  "landmark": "Near Mall"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Address updated successfully"
}
```

### **8.4 Delete Address**
```http
DELETE /addresses/{address_id}
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Address deleted successfully"
}
```

### **8.5 Set Default Address**
```http
POST /addresses/{address_id}/set-default
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Default address updated"
}
```

---

## 📄 **9. INVOICE ENDPOINTS**

### **9.1 Get Invoices**
```http
GET /invoices
```

**Headers Required:** Authorization

**Query Parameters:**
- `order_id` (integer): Filter by order
- `status` (string): paid/unpaid
- `from_date` (date): Start date
- `to_date` (date): End date
- `page` (integer): Page number
- `limit` (integer): Items per page

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "invoices": [
      {
        "id": 45,
        "invoice_number": "INV-2024-0045",
        "order_id": 101,
        "order_number": "ORD-2024-0101",
        "invoice_date": "2024-01-18",
        "total_amount": 843.00,
        "status": "paid",
        "download_url": "/invoices/45/download"
      }
    ],
    "pagination": {...}
  }
}
```

### **9.2 Get Invoice Details**
```http
GET /invoices/{invoice_id}
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "invoice": {
      "id": 45,
      "invoice_number": "INV-2024-0045",
      "invoice_date": "2024-01-18",
      "due_date": "2024-01-25",
      "customer": {
        "name": "John Doe",
        "email": "john@example.com",
        "mobile": "9876543210",
        "address": "123 Main St, Mumbai"
      },
      "items": [
        {
          "description": "Organic Rice",
          "quantity": 2,
          "rate": 225.00,
          "amount": 450.00
        }
      ],
      "summary": {
        "subtotal": 900.00,
        "discount": 90.00,
        "cgst": 21.50,
        "sgst": 21.50,
        "total": 843.00
      },
      "payment_status": "paid",
      "paid_at": "2024-01-20T15:30:00Z"
    }
  }
}
```

### **9.3 Download Invoice**
```http
GET /invoices/{invoice_id}/download
```

**Headers Required:** Authorization

**Response:** PDF file download

---

## 🚚 **10. DELIVERY PERSON ENDPOINTS**

### **10.1 Get Today's Deliveries**
```http
GET /delivery/tasks/today
```

**Headers Required:** Authorization (Delivery Person)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_deliveries": 15,
      "completed": 8,
      "pending": 7,
      "failed": 0
    },
    "deliveries": [
      {
        "id": 101,
        "order_number": "ORD-2024-0101",
        "type": "order",  // order/subscription
        "customer": {
          "name": "John Doe",
          "mobile": "9876543210",
          "address": "123 Main St, Mumbai",
          "landmark": "Near Park",
          "latitude": 19.0760,
          "longitude": 72.8777
        },
        "items": [
          {
            "product_name": "Organic Rice",
            "quantity": 2
          }
        ],
        "payment": {
          "method": "cod",
          "amount": 843.00,
          "status": "pending"
        },
        "delivery_time_slot": "10:00 AM - 11:00 AM",
        "priority": 1,
        "status": "pending",
        "notes": "Call before delivery"
      }
    ]
  }
}
```

### **10.2 Get Delivery Details**
```http
GET /delivery/tasks/{task_id}
```

**Headers Required:** Authorization (Delivery Person)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "delivery": {
      "id": 101,
      "order_number": "ORD-2024-0101",
      "customer": {...},
      "items": [...],
      "payment": {...},
      "delivery_attempts": [
        {
          "attempt_number": 1,
          "timestamp": "2024-01-20T09:30:00Z",
          "status": "customer_not_available",
          "notes": "Customer not at home"
        }
      ],
      "customer_signature": null,
      "delivery_photo": null
    }
  }
}
```

### **10.3 Start Delivery**
```http
POST /delivery/tasks/{task_id}/start
```

**Headers Required:** Authorization (Delivery Person)

**Request Body:**
```json
{
  "current_location": {
    "latitude": 19.0760,
    "longitude": 72.8777
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Delivery started",
  "data": {
    "estimated_arrival": "10 minutes"
  }
}
```

### **10.4 Update Delivery Status**
```http
PUT /delivery/tasks/{task_id}/status
```

**Headers Required:** Authorization (Delivery Person)

**Request Body:**
```json
{
  "status": "delivered",  // delivered/failed/customer_not_available
  "notes": "Delivered successfully",
  "payment_collected": 843.00,  // For COD orders
  "delivery_proof": {
    "signature": "base64_signature_image",  // optional
    "photo": "base64_delivery_photo"  // optional
  },
  "location": {
    "latitude": 19.0760,
    "longitude": 72.8777
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Delivery status updated",
  "data": {
    "next_delivery": {
      "id": 102,
      "address": "456 Next St"
    }
  }
}
```

### **10.5 Get Delivery Statistics**
```http
GET /delivery/statistics
```

**Headers Required:** Authorization (Delivery Person)

**Query Parameters:**
- `period` (string): today/week/month

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "statistics": {
      "total_deliveries": 150,
      "successful_deliveries": 145,
      "failed_deliveries": 5,
      "success_rate": 96.7,
      "total_distance_km": 450,
      "average_delivery_time_minutes": 25,
      "cash_collected": 15450.00,
      "rating": 4.8,
      "total_reviews": 85
    }
  }
}
```

---

## 🔔 **11. NOTIFICATION ENDPOINTS**

### **11.1 Get Notifications**
```http
GET /notifications
```

**Headers Required:** Authorization

**Query Parameters:**
- `type` (string): order/subscription/promotional/system
- `read` (boolean): Filter read/unread
- `page` (integer): Page number
- `limit` (integer): Items per page

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 1,
        "type": "order",
        "title": "Order Delivered",
        "message": "Your order ORD-2024-0101 has been delivered",
        "data": {
          "order_id": 101,
          "order_number": "ORD-2024-0101"
        },
        "read": false,
        "created_at": "2024-01-20T10:30:00Z"
      }
    ],
    "unread_count": 5,
    "pagination": {...}
  }
}
```

### **11.2 Mark Notification as Read**
```http
PUT /notifications/{notification_id}/read
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

### **11.3 Mark All as Read**
```http
PUT /notifications/read-all
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

### **11.4 Update Push Token**
```http
PUT /notifications/token
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "device_token": "firebase_device_token",
  "device_type": "ios"  // ios/android
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Device token updated"
}
```

---

## 🔍 **12. MISCELLANEOUS ENDPOINTS**

### **12.1 Check Pincode Serviceability**
```http
GET /delivery/check-pincode/{pincode}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "serviceable": true,
    "delivery_charge": 40.00,
    "estimated_days": 2,
    "cod_available": true
  }
}
```

### **12.2 Get App Settings**
```http
GET /settings
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "app_version": {
      "minimum_version": "1.0.0",
      "latest_version": "1.2.0",
      "force_update": false
    },
    "support": {
      "phone": "1800-123-4567",
      "email": "support@dhanvantrinaturals.com",
      "whatsapp": "9876543210"
    },
    "business_hours": {
      "delivery_start": "07:00",
      "delivery_end": "20:00"
    },
    "payment_methods": {
      "cod": {
        "enabled": true,
        "min_order": 100.00,
        "max_order": 10000.00
      }
    },
    "delivery": {
      "min_order_value": 200.00,
      "free_delivery_above": 500.00,
      "standard_delivery_charge": 40.00
    }
  }
}
```

### **12.3 Apply Coupon**
```http
POST /coupons/apply
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "coupon_code": "SAVE10",
  "order_amount": 1000.00
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "discount_type": "percentage",
    "discount_value": 10,
    "discount_amount": 100.00,
    "final_amount": 900.00,
    "message": "Coupon applied successfully"
  }
}
```

### **12.4 Get Wishlist**
```http
GET /wishlist
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "product": {
          "id": 5,
          "name": "Organic Honey",
          "price": 350.00,
          "discount_price": 320.00,
          "image": "url_to_image",
          "in_stock": true
        },
        "added_at": "2024-01-15T10:00:00Z"
      }
    ],
    "items_count": 5
  }
}
```

### **12.5 Add to Wishlist**
```http
POST /wishlist/add
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "product_id": 5
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Product added to wishlist"
}
```

### **12.6 Remove from Wishlist**
```http
DELETE /wishlist/{item_id}
```

**Headers Required:** Authorization

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Product removed from wishlist"
}
```

---

## 📊 **13. ANALYTICS ENDPOINTS**

### **13.1 Track Event**
```http
POST /analytics/track
```

**Headers Required:** Authorization

**Request Body:**
```json
{
  "event_name": "product_viewed",
  "event_data": {
    "product_id": 1,
    "category": "Groceries",
    "price": 250.00
  },
  "timestamp": "2024-01-20T10:30:00Z"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Event tracked"
}
```

---

## ❌ **ERROR RESPONSES**

All error responses follow this format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "field": "field_name"  // For validation errors
  }
}
```

### Common Error Codes:
- `UNAUTHORIZED`: Invalid or expired token
- `FORBIDDEN`: Access denied
- `NOT_FOUND`: Resource not found
- `VALIDATION_ERROR`: Input validation failed
- `INVALID_COUPON`: Coupon code invalid or expired
- `OUT_OF_STOCK`: Product out of stock
- `DELIVERY_NOT_AVAILABLE`: Delivery not available in this area
- `ORDER_CANNOT_BE_CANCELLED`: Order already shipped
- `SUBSCRIPTION_ALREADY_EXISTS`: Active subscription exists for this product

### HTTP Status Codes:
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `422`: Unprocessable Entity
- `429`: Too Many Requests
- `500`: Internal Server Error

---

## 🔄 **PAGINATION FORMAT**

All paginated endpoints return data in this format:

```json
{
  "pagination": {
    "current_page": 1,
    "total_pages": 10,
    "total_items": 195,
    "items_per_page": 20,
    "has_next": true,
    "has_previous": false
  }
}
```

---

## 📦 **WEBHOOK ENDPOINTS (For Backend)**

### **Payment Status Update**
```http
POST /webhooks/payment/status
```

**Request Body:**
```json
{
  "order_id": 101,
  "payment_id": "pay_xyz123",
  "status": "success",
  "amount": 843.00,
  "timestamp": "2024-01-20T10:30:00Z"
}
```

---

## 🔒 **RATE LIMITING**

- **Authentication endpoints**: 5 requests per minute
- **Order creation**: 10 requests per minute
- **General API**: 100 requests per minute per user

Rate limit information is included in response headers:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Requests remaining
- `X-RateLimit-Reset`: Unix timestamp when limit resets

---

This comprehensive API documentation covers all the endpoints needed for the mobile application, including customer app features and delivery person functionality. The structure follows RESTful conventions and includes proper authentication, error handling, and response formats.