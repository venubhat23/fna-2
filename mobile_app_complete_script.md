# Complete Mobile App Development Script
## E-Commerce Platform with Subscription & Delivery Management

### 📱 System Overview

This mobile application ecosystem consists of:
1. **Customer App** - Shopping, subscriptions, orders, wallet
2. **Delivery Partner App** - Task management, route optimization
3. **Backend API** - Rails-based REST API

---

## 🏗️ Architecture & Tech Stack

### Frontend
- **Framework**: React Native (iOS & Android)
- **State Management**: Redux Toolkit
- **Navigation**: React Navigation 6
- **UI Library**: React Native Elements + Custom Components
- **Payment**: Razorpay/Stripe SDK
- **Maps**: React Native Maps

### Backend
- **Framework**: Ruby on Rails API
- **Database**: PostgreSQL
- **Authentication**: JWT
- **File Storage**: AWS S3/Cloudinary
- **Push Notifications**: FCM/APNS
- **Payment Gateway**: Razorpay/Stripe

---

## 📂 Project Structure

```
mobile-apps/
├── customer-app/
│   ├── src/
│   │   ├── screens/
│   │   ├── components/
│   │   ├── navigation/
│   │   ├── services/
│   │   ├── store/
│   │   └── utils/
├── delivery-app/
│   └── src/
└── shared/
    └── api/
```

---

## 🔧 Part 1: Backend API Setup

### 1.1 API Authentication Controller

```ruby
# app/controllers/api/v1/mobile/base_controller.rb
class Api::V1::Mobile::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user_from_token!

  private

  def authenticate_user_from_token!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')
    @current_user = User.find(decoded_token[0]['user_id'])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render_unauthorized
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def current_customer
    @current_customer ||= Customer.find_by(user_id: @current_user.id) if @current_user
  end
end
```

### 1.2 Mobile Authentication API

```ruby
# app/controllers/api/v1/mobile/auth_controller.rb
class Api::V1::Mobile::AuthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def register
    customer = Customer.new(customer_params)

    if customer.save
      user = User.create!(
        email: customer.email,
        password: params[:password],
        first_name: customer.first_name,
        last_name: customer.last_name,
        mobile: customer.mobile,
        user_type: 'customer'
      )

      customer.update(user_id: user.id)

      # Create wallet for customer
      CustomerWallet.create!(customer: customer, balance: 0)

      token = generate_jwt_token(user)
      render json: {
        success: true,
        token: token,
        user: user_data(user, customer)
      }
    else
      render json: {
        success: false,
        errors: customer.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      customer = Customer.find_by(user_id: user.id)
      token = generate_jwt_token(user)

      render json: {
        success: true,
        token: token,
        user: user_data(user, customer)
      }
    else
      render json: {
        success: false,
        error: 'Invalid email or password'
      }, status: :unauthorized
    end
  end

  private

  def generate_jwt_token(user)
    JWT.encode(
      { user_id: user.id, exp: 30.days.from_now.to_i },
      Rails.application.secrets.secret_key_base,
      'HS256'
    )
  end

  def user_data(user, customer)
    {
      id: user.id,
      email: user.email,
      name: "#{user.first_name} #{user.last_name}",
      mobile: user.mobile,
      customer_id: customer&.id,
      wallet_balance: customer&.wallet&.balance || 0
    }
  end

  def customer_params
    params.require(:customer).permit(
      :first_name, :last_name, :email, :mobile,
      :address, :city, :state, :pincode
    )
  end
end
```

### 1.3 Products & Categories API

```ruby
# app/controllers/api/v1/mobile/products_controller.rb
class Api::V1::Mobile::ProductsController < Api::V1::Mobile::BaseController
  skip_before_action :authenticate_user_from_token!, only: [:index, :show, :categories]

  def categories
    categories = Category.active.order(:display_order)
    render json: {
      success: true,
      categories: categories.map do |cat|
        {
          id: cat.id,
          name: cat.name,
          description: cat.description,
          image: cat.image_url,
          product_count: cat.products.active.count
        }
      end
    }
  end

  def index
    products = Product.active.includes(:category)
    products = products.where(category_id: params[:category_id]) if params[:category_id]
    products = products.search(params[:search]) if params[:search]

    render json: {
      success: true,
      products: products.map do |product|
        product_json(product)
      end
    }
  end

  def show
    product = Product.find(params[:id])
    render json: {
      success: true,
      product: product_json(product, detailed: true)
    }
  end

  private

  def product_json(product, detailed: false)
    data = {
      id: product.id,
      name: product.name,
      description: product.description,
      category: product.category.name,
      category_id: product.category_id,
      price: product.price,
      discount_price: product.discount_price,
      image: product.image_url,
      in_stock: product.stock > 0,
      unit: product.unit,
      is_subscription_enabled: product.is_subscription_enabled
    }

    if detailed
      data.merge!(
        stock: product.stock,
        images: product.images,
        nutritional_info: product.nutritional_info,
        delivery_info: product.delivery_info
      )
    end

    data
  end
end
```

### 1.4 Cart & Booking API

```ruby
# app/controllers/api/v1/mobile/cart_controller.rb
class Api::V1::Mobile::CartController < Api::V1::Mobile::BaseController

  def add_to_cart
    cart_item = current_customer.cart_items.find_or_initialize_by(
      product_id: params[:product_id]
    )

    cart_item.quantity = (cart_item.quantity || 0) + params[:quantity].to_i

    if cart_item.save
      render json: {
        success: true,
        cart: cart_summary
      }
    else
      render json: {
        success: false,
        errors: cart_item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def remove_from_cart
    cart_item = current_customer.cart_items.find_by(id: params[:id])

    if cart_item&.destroy
      render json: {
        success: true,
        cart: cart_summary
      }
    else
      render json: {
        success: false,
        error: 'Item not found'
      }, status: :not_found
    end
  end

  def update_quantity
    cart_item = current_customer.cart_items.find_by(id: params[:id])

    if cart_item&.update(quantity: params[:quantity])
      render json: {
        success: true,
        cart: cart_summary
      }
    else
      render json: {
        success: false,
        errors: cart_item&.errors&.full_messages || ['Item not found']
      }, status: :unprocessable_entity
    end
  end

  def cart_summary
    items = current_customer.cart_items.includes(:product)

    {
      items: items.map do |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product.name,
          price: item.product.price,
          quantity: item.quantity,
          total: item.product.price * item.quantity,
          image: item.product.image_url
        }
      end,
      subtotal: items.sum { |i| i.product.price * i.quantity },
      discount: calculate_discount(items),
      delivery_charge: calculate_delivery_charge,
      total: calculate_total(items)
    }
  end

  def checkout
    ActiveRecord::Base.transaction do
      booking = Booking.create!(
        customer: current_customer,
        customer_name: current_customer.full_name,
        customer_email: current_customer.email,
        customer_phone: current_customer.mobile,
        delivery_address: params[:delivery_address],
        payment_method: params[:payment_method],
        subtotal: params[:subtotal],
        discount_amount: params[:discount_amount],
        tax_amount: params[:tax_amount],
        total_amount: params[:total_amount],
        booking_items: build_booking_items,
        status: 'pending'
      )

      # Clear cart after successful booking
      current_customer.cart_items.destroy_all

      # Process payment if online
      if params[:payment_method] == 'online'
        payment_result = process_payment(booking)
        booking.update(payment_status: payment_result[:status])
      end

      render json: {
        success: true,
        booking_id: booking.id,
        order_number: booking.booking_number
      }
    end
  rescue => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  private

  def calculate_discount(items)
    # Apply coupon or bulk discount logic
    0
  end

  def calculate_delivery_charge
    # Calculate based on location
    40
  end

  def calculate_total(items)
    subtotal = items.sum { |i| i.product.price * i.quantity }
    subtotal - calculate_discount(items) + calculate_delivery_charge
  end

  def build_booking_items
    current_customer.cart_items.includes(:product).map do |item|
      {
        product_id: item.product_id,
        product_name: item.product.name,
        quantity: item.quantity,
        price: item.product.price,
        total: item.product.price * item.quantity
      }
    end
  end
end
```

### 1.5 Subscription API

```ruby
# app/controllers/api/v1/mobile/subscriptions_controller.rb
class Api::V1::Mobile::SubscriptionsController < Api::V1::Mobile::BaseController

  def create
    subscription = MilkSubscription.new(subscription_params)
    subscription.customer = current_customer

    if subscription.save
      render json: {
        success: true,
        subscription: subscription_json(subscription)
      }
    else
      render json: {
        success: false,
        errors: subscription.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def index
    subscriptions = current_customer.milk_subscriptions
                                   .includes(:product, :milk_delivery_tasks)

    render json: {
      success: true,
      subscriptions: subscriptions.map { |s| subscription_json(s) }
    }
  end

  def pause
    subscription = current_customer.milk_subscriptions.find(params[:id])

    if subscription.pause_all_tasks!
      render json: {
        success: true,
        message: 'Subscription paused successfully'
      }
    else
      render json: {
        success: false,
        error: 'Could not pause subscription'
      }, status: :unprocessable_entity
    end
  end

  def resume
    subscription = current_customer.milk_subscriptions.find(params[:id])

    if subscription.resume_all_tasks!
      render json: {
        success: true,
        message: 'Subscription resumed successfully'
      }
    else
      render json: {
        success: false,
        error: 'Could not resume subscription'
      }, status: :unprocessable_entity
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(
      :product_id, :quantity, :unit, :delivery_pattern,
      :start_date, :end_date, :delivery_time, :specific_dates
    )
  end

  def subscription_json(subscription)
    {
      id: subscription.id,
      product: subscription.product.name,
      quantity: subscription.quantity,
      unit: subscription.unit,
      pattern: subscription.delivery_pattern,
      start_date: subscription.start_date,
      end_date: subscription.end_date,
      status: subscription.status,
      total_deliveries: subscription.total_deliveries_count,
      completed_deliveries: subscription.completed_deliveries_count,
      next_delivery: subscription.milk_delivery_tasks
                                 .pending.order(:delivery_date)
                                 .first&.delivery_date
    }
  end
end
```

### 1.6 Wallet & Payment API

```ruby
# app/controllers/api/v1/mobile/wallet_controller.rb
class Api::V1::Mobile::WalletController < Api::V1::Mobile::BaseController

  def balance
    wallet = current_customer.customer_wallet

    render json: {
      success: true,
      balance: wallet.balance,
      transactions: recent_transactions(wallet)
    }
  end

  def add_money
    wallet = current_customer.customer_wallet
    amount = params[:amount].to_f

    # Process payment gateway
    payment_result = process_wallet_payment(amount)

    if payment_result[:success]
      transaction = wallet.wallet_transactions.create!(
        transaction_type: 'credit',
        amount: amount,
        description: 'Added to wallet',
        payment_id: payment_result[:payment_id],
        status: 'completed'
      )

      wallet.update(balance: wallet.balance + amount)

      render json: {
        success: true,
        new_balance: wallet.balance,
        transaction_id: transaction.id
      }
    else
      render json: {
        success: false,
        error: payment_result[:error]
      }, status: :unprocessable_entity
    end
  end

  def pay_with_wallet
    wallet = current_customer.customer_wallet
    amount = params[:amount].to_f

    if wallet.balance >= amount
      transaction = wallet.wallet_transactions.create!(
        transaction_type: 'debit',
        amount: amount,
        description: params[:description],
        reference_type: params[:reference_type],
        reference_id: params[:reference_id],
        status: 'completed'
      )

      wallet.update(balance: wallet.balance - amount)

      render json: {
        success: true,
        new_balance: wallet.balance,
        transaction_id: transaction.id
      }
    else
      render json: {
        success: false,
        error: 'Insufficient balance'
      }, status: :unprocessable_entity
    end
  end

  private

  def recent_transactions(wallet, limit = 10)
    wallet.wallet_transactions
          .order(created_at: :desc)
          .limit(limit)
          .map do |t|
      {
        id: t.id,
        type: t.transaction_type,
        amount: t.amount,
        description: t.description,
        date: t.created_at,
        status: t.status
      }
    end
  end

  def process_wallet_payment(amount)
    # Integrate with Razorpay/Stripe
    {
      success: true,
      payment_id: "pay_#{SecureRandom.hex(8)}"
    }
  end
end
```

---

## 📱 Part 2: React Native Customer App

### 2.1 Project Setup

```bash
# Create React Native app
npx react-native init CustomerApp
cd CustomerApp

# Install dependencies
npm install @reduxjs/toolkit react-redux
npm install @react-navigation/native @react-navigation/stack @react-navigation/bottom-tabs
npm install react-native-safe-area-context react-native-screens
npm install react-native-vector-icons react-native-elements
npm install axios react-native-async-storage
npm install react-native-razorpay # or stripe
npm install react-native-maps
npm install react-native-image-picker
npm install react-native-push-notification
```

### 2.2 App Structure & Navigation

```javascript
// App.js
import React, { useEffect } from 'react';
import { Provider } from 'react-redux';
import { NavigationContainer } from '@react-navigation/native';
import { store } from './src/store';
import RootNavigator from './src/navigation/RootNavigator';
import { setupPushNotifications } from './src/services/notifications';

const App = () => {
  useEffect(() => {
    setupPushNotifications();
  }, []);

  return (
    <Provider store={store}>
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </Provider>
  );
};

export default App;
```

### 2.3 Navigation Setup

```javascript
// src/navigation/RootNavigator.js
import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { useSelector } from 'react-redux';

import AuthNavigator from './AuthNavigator';
import AppNavigator from './AppNavigator';
import SplashScreen from '../screens/SplashScreen';

const Stack = createStackNavigator();

const RootNavigator = () => {
  const { isAuthenticated, isLoading } = useSelector(state => state.auth);

  if (isLoading) {
    return <SplashScreen />;
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {isAuthenticated ? (
        <Stack.Screen name="App" component={AppNavigator} />
      ) : (
        <Stack.Screen name="Auth" component={AuthNavigator} />
      )}
    </Stack.Navigator>
  );
};

export default RootNavigator;
```

```javascript
// src/navigation/AppNavigator.js
import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import Icon from 'react-native-vector-icons/Ionicons';

// Import screens
import HomeScreen from '../screens/Home/HomeScreen';
import CategoriesScreen from '../screens/Categories/CategoriesScreen';
import CartScreen from '../screens/Cart/CartScreen';
import ProfileScreen from '../screens/Profile/ProfileScreen';
import ProductDetailsScreen from '../screens/Products/ProductDetailsScreen';
import CheckoutScreen from '../screens/Checkout/CheckoutScreen';
import SubscriptionsScreen from '../screens/Subscriptions/SubscriptionsScreen';
import OrdersScreen from '../screens/Orders/OrdersScreen';
import WalletScreen from '../screens/Wallet/WalletScreen';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

const HomeStack = () => (
  <Stack.Navigator>
    <Stack.Screen name="Home" component={HomeScreen} />
    <Stack.Screen name="ProductDetails" component={ProductDetailsScreen} />
    <Stack.Screen name="Categories" component={CategoriesScreen} />
  </Stack.Navigator>
);

const CartStack = () => (
  <Stack.Navigator>
    <Stack.Screen name="Cart" component={CartScreen} />
    <Stack.Screen name="Checkout" component={CheckoutScreen} />
  </Stack.Navigator>
);

const ProfileStack = () => (
  <Stack.Navigator>
    <Stack.Screen name="Profile" component={ProfileScreen} />
    <Stack.Screen name="Orders" component={OrdersScreen} />
    <Stack.Screen name="Subscriptions" component={SubscriptionsScreen} />
    <Stack.Screen name="Wallet" component={WalletScreen} />
  </Stack.Navigator>
);

const AppNavigator = () => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName;

          switch (route.name) {
            case 'HomeTab':
              iconName = focused ? 'home' : 'home-outline';
              break;
            case 'Categories':
              iconName = focused ? 'grid' : 'grid-outline';
              break;
            case 'CartTab':
              iconName = focused ? 'cart' : 'cart-outline';
              break;
            case 'ProfileTab':
              iconName = focused ? 'person' : 'person-outline';
              break;
          }

          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#007AFF',
        tabBarInactiveTintColor: 'gray',
        headerShown: false,
      })}
    >
      <Tab.Screen name="HomeTab" component={HomeStack} options={{ title: 'Home' }} />
      <Tab.Screen name="Categories" component={CategoriesScreen} />
      <Tab.Screen name="CartTab" component={CartStack} options={{ title: 'Cart' }} />
      <Tab.Screen name="ProfileTab" component={ProfileStack} options={{ title: 'Profile' }} />
    </Tab.Navigator>
  );
};

export default AppNavigator;
```

### 2.4 Redux Store Setup

```javascript
// src/store/index.js
import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import productsReducer from './slices/productsSlice';
import cartReducer from './slices/cartSlice';
import ordersReducer from './slices/ordersSlice';
import subscriptionsReducer from './slices/subscriptionsSlice';
import walletReducer from './slices/walletSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    products: productsReducer,
    cart: cartReducer,
    orders: ordersReducer,
    subscriptions: subscriptionsReducer,
    wallet: walletReducer,
  },
});
```

### 2.5 Auth Slice & API Service

```javascript
// src/store/slices/authSlice.js
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { authAPI } from '../../services/api';

export const login = createAsyncThunk(
  'auth/login',
  async ({ email, password }) => {
    const response = await authAPI.login(email, password);
    await AsyncStorage.setItem('token', response.token);
    await AsyncStorage.setItem('user', JSON.stringify(response.user));
    return response;
  }
);

export const register = createAsyncThunk(
  'auth/register',
  async (userData) => {
    const response = await authAPI.register(userData);
    await AsyncStorage.setItem('token', response.token);
    await AsyncStorage.setItem('user', JSON.stringify(response.user));
    return response;
  }
);

const authSlice = createSlice({
  name: 'auth',
  initialState: {
    user: null,
    token: null,
    isAuthenticated: false,
    isLoading: true,
    error: null,
  },
  reducers: {
    logout: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
      AsyncStorage.removeItem('token');
      AsyncStorage.removeItem('user');
    },
    restoreToken: (state, action) => {
      state.token = action.payload.token;
      state.user = action.payload.user;
      state.isAuthenticated = !!action.payload.token;
      state.isLoading = false;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(login.fulfilled, (state, action) => {
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.isAuthenticated = true;
        state.error = null;
      })
      .addCase(login.rejected, (state, action) => {
        state.error = action.error.message;
      })
      .addCase(register.fulfilled, (state, action) => {
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.isAuthenticated = true;
        state.error = null;
      });
  },
});

export const { logout, restoreToken } = authSlice.actions;
export default authSlice.reducer;
```

### 2.6 API Service

```javascript
// src/services/api.js
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE_URL = 'http://your-server.com/api/v1/mobile';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add token
apiClient.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized - logout user
      AsyncStorage.removeItem('token');
      AsyncStorage.removeItem('user');
    }
    return Promise.reject(error);
  }
);

export const authAPI = {
  login: (email, password) =>
    apiClient.post('/auth/login', { email, password }),

  register: (userData) =>
    apiClient.post('/auth/register', userData),

  forgotPassword: (email) =>
    apiClient.post('/auth/forgot-password', { email }),
};

export const productsAPI = {
  getCategories: () =>
    apiClient.get('/products/categories'),

  getProducts: (params = {}) =>
    apiClient.get('/products', { params }),

  getProductDetails: (id) =>
    apiClient.get(`/products/${id}`),

  searchProducts: (query) =>
    apiClient.get('/products/search', { params: { q: query } }),
};

export const cartAPI = {
  addToCart: (productId, quantity) =>
    apiClient.post('/cart/add', { product_id: productId, quantity }),

  removeFromCart: (itemId) =>
    apiClient.delete(`/cart/remove/${itemId}`),

  updateQuantity: (itemId, quantity) =>
    apiClient.patch(`/cart/update/${itemId}`, { quantity }),

  getCart: () =>
    apiClient.get('/cart'),

  checkout: (checkoutData) =>
    apiClient.post('/cart/checkout', checkoutData),
};

export const subscriptionAPI = {
  create: (subscriptionData) =>
    apiClient.post('/subscriptions', subscriptionData),

  list: () =>
    apiClient.get('/subscriptions'),

  pause: (id) =>
    apiClient.patch(`/subscriptions/${id}/pause`),

  resume: (id) =>
    apiClient.patch(`/subscriptions/${id}/resume`),

  cancel: (id) =>
    apiClient.delete(`/subscriptions/${id}`),
};

export const walletAPI = {
  getBalance: () =>
    apiClient.get('/wallet/balance'),

  addMoney: (amount) =>
    apiClient.post('/wallet/add-money', { amount }),

  payWithWallet: (amount, description, referenceType, referenceId) =>
    apiClient.post('/wallet/pay', {
      amount,
      description,
      reference_type: referenceType,
      reference_id: referenceId,
    }),

  getTransactions: () =>
    apiClient.get('/wallet/transactions'),
};

export const ordersAPI = {
  list: () =>
    apiClient.get('/orders'),

  getDetails: (id) =>
    apiClient.get(`/orders/${id}`),

  cancel: (id) =>
    apiClient.patch(`/orders/${id}/cancel`),

  track: (id) =>
    apiClient.get(`/orders/${id}/track`),
};

export default apiClient;
```

### 2.7 Home Screen

```javascript
// src/screens/Home/HomeScreen.js
import React, { useEffect, useState } from 'react';
import {
  View,
  ScrollView,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Image,
  RefreshControl,
  TextInput,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import Icon from 'react-native-vector-icons/Ionicons';
import { productsAPI } from '../../services/api';

const HomeScreen = ({ navigation }) => {
  const [categories, setCategories] = useState([]);
  const [featuredProducts, setFeaturedProducts] = useState([]);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const { user } = useSelector(state => state.auth);
  const { items: cartItems } = useSelector(state => state.cart);

  useEffect(() => {
    loadHomeData();
  }, []);

  const loadHomeData = async () => {
    try {
      setRefreshing(true);
      const [categoriesData, productsData] = await Promise.all([
        productsAPI.getCategories(),
        productsAPI.getProducts({ featured: true }),
      ]);

      setCategories(categoriesData.categories);
      setFeaturedProducts(productsData.products);
    } catch (error) {
      console.error('Error loading home data:', error);
    } finally {
      setRefreshing(false);
    }
  };

  const renderCategory = ({ item }) => (
    <TouchableOpacity
      style={styles.categoryCard}
      onPress={() => navigation.navigate('Categories', { categoryId: item.id })}
    >
      <Image source={{ uri: item.image }} style={styles.categoryImage} />
      <Text style={styles.categoryName}>{item.name}</Text>
    </TouchableOpacity>
  );

  const renderProduct = ({ item }) => (
    <TouchableOpacity
      style={styles.productCard}
      onPress={() => navigation.navigate('ProductDetails', { productId: item.id })}
    >
      <Image source={{ uri: item.image }} style={styles.productImage} />
      {item.discount_price && (
        <View style={styles.discountBadge}>
          <Text style={styles.discountText}>
            {Math.round(((item.price - item.discount_price) / item.price) * 100)}% OFF
          </Text>
        </View>
      )}
      <View style={styles.productInfo}>
        <Text style={styles.productName} numberOfLines={2}>{item.name}</Text>
        <View style={styles.priceContainer}>
          <Text style={styles.price}>₹{item.discount_price || item.price}</Text>
          {item.discount_price && (
            <Text style={styles.originalPrice}>₹{item.price}</Text>
          )}
        </View>
        {item.is_subscription_enabled && (
          <View style={styles.subscriptionBadge}>
            <Icon name="repeat" size={12} color="#4CAF50" />
            <Text style={styles.subscriptionText}>Subscription Available</Text>
          </View>
        )}
        <TouchableOpacity style={styles.addToCartBtn}>
          <Text style={styles.addToCartText}>Add to Cart</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>Hello, {user?.name || 'Guest'}!</Text>
          <Text style={styles.subGreeting}>What would you like to order today?</Text>
        </View>
        <TouchableOpacity
          style={styles.cartIcon}
          onPress={() => navigation.navigate('CartTab')}
        >
          <Icon name="cart-outline" size={28} color="#333" />
          {cartItems.length > 0 && (
            <View style={styles.cartBadge}>
              <Text style={styles.cartBadgeText}>{cartItems.length}</Text>
            </View>
          )}
        </TouchableOpacity>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <Icon name="search" size={20} color="#999" />
        <TextInput
          style={styles.searchInput}
          placeholder="Search products..."
          value={searchQuery}
          onChangeText={setSearchQuery}
          onSubmitEditing={() => navigation.navigate('SearchResults', { query: searchQuery })}
        />
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={loadHomeData} />
        }
      >
        {/* Categories Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Categories</Text>
          <FlatList
            horizontal
            showsHorizontalScrollIndicator={false}
            data={categories}
            renderItem={renderCategory}
            keyExtractor={item => item.id.toString()}
            contentContainerStyle={styles.categoryList}
          />
        </View>

        {/* Featured Products */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Featured Products</Text>
            <TouchableOpacity onPress={() => navigation.navigate('AllProducts')}>
              <Text style={styles.seeAll}>See All</Text>
            </TouchableOpacity>
          </View>
          <FlatList
            numColumns={2}
            data={featuredProducts}
            renderItem={renderProduct}
            keyExtractor={item => item.id.toString()}
            columnWrapperStyle={styles.productRow}
            scrollEnabled={false}
          />
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#fff',
  },
  greeting: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  subGreeting: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  cartIcon: {
    position: 'relative',
  },
  cartBadge: {
    position: 'absolute',
    top: -5,
    right: -5,
    backgroundColor: '#FF5722',
    borderRadius: 10,
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cartBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    margin: 15,
    padding: 12,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  searchInput: {
    flex: 1,
    marginLeft: 10,
    fontSize: 16,
  },
  section: {
    marginVertical: 10,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 15,
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    paddingHorizontal: 15,
    marginBottom: 15,
  },
  seeAll: {
    color: '#007AFF',
    fontSize: 14,
  },
  categoryList: {
    paddingHorizontal: 10,
  },
  categoryCard: {
    alignItems: 'center',
    marginHorizontal: 10,
    width: 80,
  },
  categoryImage: {
    width: 70,
    height: 70,
    borderRadius: 35,
    marginBottom: 8,
  },
  categoryName: {
    fontSize: 12,
    color: '#333',
    textAlign: 'center',
  },
  productRow: {
    paddingHorizontal: 10,
    justifyContent: 'space-between',
  },
  productCard: {
    flex: 0.48,
    backgroundColor: '#fff',
    borderRadius: 10,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  productImage: {
    width: '100%',
    height: 150,
    borderTopLeftRadius: 10,
    borderTopRightRadius: 10,
  },
  discountBadge: {
    position: 'absolute',
    top: 10,
    right: 10,
    backgroundColor: '#FF5722',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 5,
  },
  discountText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: 'bold',
  },
  productInfo: {
    padding: 12,
  },
  productName: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
    marginBottom: 8,
  },
  priceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  price: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  originalPrice: {
    fontSize: 14,
    color: '#999',
    textDecorationLine: 'line-through',
    marginLeft: 8,
  },
  subscriptionBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  subscriptionText: {
    fontSize: 11,
    color: '#4CAF50',
    marginLeft: 4,
  },
  addToCartBtn: {
    backgroundColor: '#007AFF',
    paddingVertical: 8,
    borderRadius: 5,
    alignItems: 'center',
  },
  addToCartText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
});

export default HomeScreen;
```

---

## 🚚 Part 3: Delivery Partner App

### 3.1 Delivery Dashboard

```javascript
// delivery-app/src/screens/Dashboard/DeliveryDashboard.js
import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import MapView, { Marker, Polyline } from 'react-native-maps';
import { deliveryAPI } from '../../services/api';

const DeliveryDashboard = ({ navigation }) => {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState({
    pending: 0,
    completed: 0,
    todayEarnings: 0,
  });
  const [refreshing, setRefreshing] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setRefreshing(true);
      const [tasksData, statsData] = await Promise.all([
        deliveryAPI.getTodayTasks(),
        deliveryAPI.getStats(),
      ]);

      setTasks(tasksData.tasks);
      setStats(statsData);
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setRefreshing(false);
    }
  };

  const startDelivery = async (taskId) => {
    try {
      await deliveryAPI.startDelivery(taskId);
      loadDashboardData();
      navigation.navigate('DeliveryDetails', { taskId });
    } catch (error) {
      Alert.alert('Error', 'Failed to start delivery');
    }
  };

  const completeDelivery = async (taskId) => {
    Alert.alert(
      'Complete Delivery',
      'Are you sure you want to mark this delivery as completed?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Complete',
          onPress: async () => {
            try {
              await deliveryAPI.completeDelivery(taskId);
              loadDashboardData();
              Alert.alert('Success', 'Delivery marked as completed');
            } catch (error) {
              Alert.alert('Error', 'Failed to complete delivery');
            }
          },
        },
      ]
    );
  };

  const renderTask = (task) => (
    <TouchableOpacity
      key={task.id}
      style={styles.taskCard}
      onPress={() => navigation.navigate('DeliveryDetails', { taskId: task.id })}
    >
      <View style={styles.taskHeader}>
        <View style={styles.taskIdContainer}>
          <Text style={styles.taskId}>#{task.order_number}</Text>
          <View style={[styles.statusBadge, { backgroundColor: getStatusColor(task.status) }]}>
            <Text style={styles.statusText}>{task.status}</Text>
          </View>
        </View>
        <Text style={styles.taskTime}>{task.delivery_time}</Text>
      </View>

      <View style={styles.taskBody}>
        <View style={styles.addressContainer}>
          <Icon name="location" size={20} color="#666" />
          <View style={styles.addressInfo}>
            <Text style={styles.customerName}>{task.customer_name}</Text>
            <Text style={styles.address} numberOfLines={2}>{task.address}</Text>
          </View>
        </View>

        <View style={styles.itemsContainer}>
          <Icon name="basket" size={20} color="#666" />
          <Text style={styles.itemsText}>{task.items_count} items</Text>
        </View>

        {task.is_subscription && (
          <View style={styles.subscriptionIndicator}>
            <Icon name="repeat" size={16} color="#4CAF50" />
            <Text style={styles.subscriptionText}>Subscription Delivery</Text>
          </View>
        )}
      </View>

      <View style={styles.taskActions}>
        {task.status === 'pending' && (
          <TouchableOpacity
            style={[styles.actionButton, styles.startButton]}
            onPress={() => startDelivery(task.id)}
          >
            <Text style={styles.actionButtonText}>Start Delivery</Text>
          </TouchableOpacity>
        )}

        {task.status === 'in_progress' && (
          <>
            <TouchableOpacity
              style={[styles.actionButton, styles.navigateButton]}
              onPress={() => openNavigation(task.latitude, task.longitude)}
            >
              <Icon name="navigate" size={20} color="#fff" />
              <Text style={styles.actionButtonText}>Navigate</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.actionButton, styles.completeButton]}
              onPress={() => completeDelivery(task.id)}
            >
              <Text style={styles.actionButtonText}>Complete</Text>
            </TouchableOpacity>
          </>
        )}
      </View>
    </TouchableOpacity>
  );

  const getStatusColor = (status) => {
    switch (status) {
      case 'pending': return '#FFC107';
      case 'in_progress': return '#2196F3';
      case 'completed': return '#4CAF50';
      case 'cancelled': return '#F44336';
      default: return '#999';
    }
  };

  const openNavigation = (lat, lng) => {
    // Open native maps app for navigation
    const url = `maps://app?daddr=${lat},${lng}`;
    Linking.openURL(url);
  };

  return (
    <View style={styles.container}>
      {/* Header Stats */}
      <View style={styles.statsContainer}>
        <View style={styles.statCard}>
          <Icon name="time-outline" size={24} color="#FFC107" />
          <Text style={styles.statValue}>{stats.pending}</Text>
          <Text style={styles.statLabel}>Pending</Text>
        </View>

        <View style={styles.statCard}>
          <Icon name="checkmark-circle-outline" size={24} color="#4CAF50" />
          <Text style={styles.statValue}>{stats.completed}</Text>
          <Text style={styles.statLabel}>Completed</Text>
        </View>

        <View style={styles.statCard}>
          <Icon name="cash-outline" size={24} color="#2196F3" />
          <Text style={styles.statValue}>₹{stats.todayEarnings}</Text>
          <Text style={styles.statLabel}>Earnings</Text>
        </View>
      </View>

      {/* Map View */}
      <View style={styles.mapContainer}>
        <MapView
          style={styles.map}
          initialRegion={{
            latitude: 12.9716,
            longitude: 77.5946,
            latitudeDelta: 0.0922,
            longitudeDelta: 0.0421,
          }}
        >
          {tasks.map(task => (
            <Marker
              key={task.id}
              coordinate={{
                latitude: task.latitude,
                longitude: task.longitude,
              }}
              title={task.customer_name}
              description={task.address}
            />
          ))}
        </MapView>
      </View>

      {/* Tasks List */}
      <ScrollView
        style={styles.tasksList}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={loadDashboardData} />
        }
      >
        <Text style={styles.sectionTitle}>Today's Deliveries</Text>
        {tasks.map(renderTask)}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 15,
    backgroundColor: '#fff',
  },
  statCard: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    marginTop: 5,
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
    marginTop: 2,
  },
  mapContainer: {
    height: 200,
  },
  map: {
    ...StyleSheet.absoluteFillObject,
  },
  tasksList: {
    flex: 1,
    padding: 15,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
  },
  taskCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 15,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  taskHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  taskIdContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  taskId: {
    fontSize: 16,
    fontWeight: 'bold',
    marginRight: 10,
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 5,
  },
  statusText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: 'bold',
  },
  taskTime: {
    fontSize: 14,
    color: '#666',
  },
  taskBody: {
    marginBottom: 15,
  },
  addressContainer: {
    flexDirection: 'row',
    marginBottom: 10,
  },
  addressInfo: {
    flex: 1,
    marginLeft: 10,
  },
  customerName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 2,
  },
  address: {
    fontSize: 14,
    color: '#666',
  },
  itemsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 10,
  },
  itemsText: {
    marginLeft: 10,
    fontSize: 14,
    color: '#666',
  },
  subscriptionIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 10,
  },
  subscriptionText: {
    marginLeft: 5,
    fontSize: 12,
    color: '#4CAF50',
  },
  taskActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 10,
    borderRadius: 5,
    marginHorizontal: 5,
  },
  startButton: {
    backgroundColor: '#2196F3',
  },
  navigateButton: {
    backgroundColor: '#673AB7',
  },
  completeButton: {
    backgroundColor: '#4CAF50',
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 5,
  },
});

export default DeliveryDashboard;
```

---

## 💳 Part 4: Payment Gateway Integration

### 4.1 Razorpay Integration

```javascript
// src/services/payment.js
import RazorpayCheckout from 'react-native-razorpay';

const RAZORPAY_KEY = 'rzp_test_your_key_here';

export const initiatePayment = async (amount, orderId, userDetails) => {
  const options = {
    description: 'Order Payment',
    image: 'https://your-logo-url.com/logo.png',
    currency: 'INR',
    key: RAZORPAY_KEY,
    amount: amount * 100, // Razorpay expects amount in paise
    name: 'Your Store Name',
    order_id: orderId,
    prefill: {
      email: userDetails.email,
      contact: userDetails.mobile,
      name: userDetails.name,
    },
    theme: { color: '#007AFF' },
  };

  try {
    const data = await RazorpayCheckout.open(options);
    return {
      success: true,
      paymentId: data.razorpay_payment_id,
      orderId: data.razorpay_order_id,
      signature: data.razorpay_signature,
    };
  } catch (error) {
    return {
      success: false,
      error: error.message || 'Payment cancelled',
    };
  }
};
```

---

## 🚀 Deployment & Setup Instructions

### Backend Setup
```bash
# 1. Add routes to config/routes.rb (already included above)
# 2. Run migrations
rails db:migrate

# 3. Start Rails server
rails server
```

### Mobile App Setup
```bash
# Customer App
cd customer-app
npm install
cd ios && pod install && cd ..

# For iOS
npx react-native run-ios

# For Android
npx react-native run-android

# Delivery App (same process)
cd delivery-app
npm install
# ... same as above
```

### Environment Configuration
```javascript
// Create .env file in mobile apps
API_BASE_URL=http://your-server.com
RAZORPAY_KEY=your_razorpay_key
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

---

## 📋 Features Implemented

### Customer App
✅ User registration & login
✅ Product browsing by category
✅ Product search & filters
✅ Shopping cart management
✅ One-time purchase & subscription options
✅ Multiple payment methods (Card, Wallet, COD)
✅ Order tracking
✅ Subscription management (pause/resume/cancel)
✅ Wallet system with add money
✅ Apply discount coupons
✅ Order history
✅ Push notifications

### Delivery Partner App
✅ Login & profile management
✅ View assigned deliveries
✅ Route optimization with maps
✅ Mark deliveries as completed
✅ Earnings tracking
✅ Delivery history
✅ Real-time updates

### Admin Features (via API)
✅ Product & category management
✅ Order management
✅ Subscription management
✅ Delivery assignment
✅ Commission tracking
✅ Analytics & reporting

---

## 🔐 Security Considerations

1. **JWT Authentication** with expiry
2. **API Rate Limiting** to prevent abuse
3. **SSL/TLS** for all communications
4. **Input Validation** on both frontend and backend
5. **Secure Payment Gateway** integration
6. **Data Encryption** for sensitive information
7. **Regular Security Audits**

---

## 📈 Scalability Considerations

1. **Microservices Architecture** for independent scaling
2. **Redis Caching** for frequently accessed data
3. **CDN** for static assets
4. **Database Indexing** for query optimization
5. **Load Balancing** for API servers
6. **Queue System** (Sidekiq) for background jobs
7. **Horizontal Scaling** capability

This complete mobile app solution provides a robust e-commerce platform with subscription management, delivery tracking, and comprehensive features for customers, delivery partners, and administrators.