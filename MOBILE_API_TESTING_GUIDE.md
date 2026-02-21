# 📱 Dhanvantri Mobile API - Complete Testing Guide

## 🚀 Quick Setup & Auto-Testing

### 1. Import Postman Collection & Environment

**Files to Import:**
- Collection: `Dhanvantri_Complete_Mobile_API.postman_collection.json`
- Environment: `Dhanvantri_Mobile_API.postman_environment.json`

### 2. Automatic Features ✨

The collection is designed to be **100% automatic**:

- ✅ **Auto-generates unique test data** for each session
- ✅ **Automatic token management** - saves and uses JWT tokens
- ✅ **Auto-saves IDs** - product, category, booking, subscription IDs
- ✅ **Smart error handling** with helpful console messages
- ✅ **Complete test coverage** for all endpoints
- ✅ **Environment switching** between customer and delivery person

## 🎯 Usage Instructions

### Step 1: Start Your Rails Server
```bash
cd /path/to/ecommerce-store
rails server -p 3000
```

### Step 2: Run the Complete Test Suite

**Option A: Run Individual Folders**
1. **🔐 Authentication** - Test registration and login
2. **🛍️ E-commerce - Catalog** - Browse products and categories
3. **🚚 Delivery & Validation** - Test delivery logic
4. **🛒 Orders & Bookings** - Place and manage orders
5. **📅 Subscriptions** - Test subscription management
6. **👤 Customer Profile** - Profile management
7. **🚚 Delivery Person** - Delivery operations

**Option B: Run Everything Automatically**
1. Click on **"🧪 Test Suite - Run All"** folder
2. Click **"Run Collection"** button
3. Let it run automatically - everything is handled!

### Step 3: Monitor Results

The collection provides:
- ✅ **Real-time console logs** with detailed information
- ✅ **Test assertions** that verify API responses
- ✅ **Automatic data flow** between requests
- ✅ **Error handling** with meaningful messages

## 📊 What Gets Tested Automatically

### 🔐 **Authentication Flow**
- ✅ Customer registration with unique data
- ✅ Customer login with JWT token management
- ✅ Delivery person login (if available)
- ✅ Password reset functionality

### 🛍️ **E-commerce Operations**
- ✅ Category browsing with product counts
- ✅ Product listing with pagination and filters
- ✅ Product search functionality
- ✅ Product details with nutrition info
- ✅ Featured products display

### 🚚 **Delivery Management**
- ✅ Pincode validation for delivery
- ✅ Product delivery validation
- ✅ Bulk delivery operations
- ✅ Individual delivery tracking

### 🛒 **Order Management**
- ✅ Booking creation with validation
- ✅ Order history retrieval
- ✅ Order status tracking
- ✅ Payment method handling

### 📅 **Subscription System**
- ✅ Subscription creation for recurring orders
- ✅ Subscription management (pause/resume/cancel)
- ✅ Delivery schedule management
- ✅ Subscription history tracking

### 👤 **Profile Management**
- ✅ Customer profile retrieval
- ✅ Profile updates with validation
- ✅ Address management

## 🔧 Advanced Features

### **Smart Token Management**
- Automatically saves JWT tokens after login
- Switches between customer and delivery person tokens
- Handles token expiration gracefully

### **Dynamic Test Data**
- Generates unique email addresses for each test run
- Creates valid mobile numbers automatically
- Uses timestamp-based data to avoid conflicts

### **Comprehensive Error Handling**
- Provides helpful console messages for failures
- Handles missing data gracefully
- Shows expected vs actual behavior

### **Environment Variables Auto-Set**
```javascript
// These are set automatically:
- base_url: "http://localhost:3000"
- test_email: "customer{timestamp}@dhanvantri.com"
- test_mobile: "98765{5-digits}"
- test_password: "Dhanvantri@123"
- auth_token: "{JWT-token}"
- customer_id: "{auto-saved}"
- product_id: "{auto-saved}"
- booking_id: "{auto-saved}"
// ... and more
```

## 🐞 Debugging Tips

### **Console Output Examples**
```
✅ Registration successful! Token saved automatically.
✅ Customer ID: 123
✅ Product ID saved: 456
✅ Booking created with ID: 789
✅ Switched to delivery person token
```

### **Common Issues & Solutions**

**❌ "Authentication required"**
- Solution: Run the Authentication folder first
- The token is automatically saved for subsequent requests

**❌ "Product not found"**
- Solution: Run E-commerce catalog requests first
- Product IDs are auto-saved from the product list

**❌ "Delivery person login failed"**
- This is expected if no delivery person exists in the database
- The tests handle this gracefully

**❌ "Server connection refused"**
- Make sure Rails server is running on port 3000
- Check if the base_url environment variable is correct

## 📈 Test Results Interpretation

### **Green Tests ✅**
- API endpoint is working correctly
- Data is being saved/retrieved properly
- Authentication is functioning

### **Yellow/Orange Tests ⚠️**
- Expected behavior (like missing delivery persons)
- Graceful error handling working correctly

### **Red Tests ❌**
- Actual API issues that need fixing
- Server connectivity problems
- Data validation failures

## 🔄 Re-running Tests

The collection is designed to be run multiple times:
- Each run generates new unique test data
- No manual cleanup required
- Tokens are refreshed automatically
- Previous test data doesn't interfere

## 📞 Support

If you encounter any issues:

1. **Check Console Logs** - Detailed information is provided
2. **Verify Server Status** - Ensure Rails server is running
3. **Check Environment** - Ensure variables are set correctly
4. **Run Individual Requests** - Test specific endpoints

## 🎉 Expected Output

When everything works correctly, you'll see:

```
=== API Test Summary ===
Base URL: http://localhost:3000
Test Email: customer1708123456@dhanvantri.com
Test Mobile: 9876512345
Auth Token Set: Yes
Customer ID: 123
Product ID: 456
========================

✅ All tests passing
✅ 40+ API endpoints tested
✅ Authentication working
✅ E-commerce features functional
✅ Delivery system operational
```

---

## 🚀 **Ready to Test!**

Simply import the collection and environment, then click **"Run Collection"** - everything else is automated! 🎯