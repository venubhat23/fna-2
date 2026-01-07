# InsureBook React App - Authentication API Integration

## Base Configuration

```javascript
// config/api.js
const API_BASE_URL = process.env.NODE_ENV === 'production'
  ? 'https://your-production-domain.onrender.com/api/v1'
  : 'http://localhost:3000/api/v1';

export const API_ENDPOINTS = {
  LOGIN: `${API_BASE_URL}/auth/login`,
  REGISTER: `${API_BASE_URL}/auth/register`
};
```

## 1. User Registration API

### React Component Example

```jsx
import React, { useState } from 'react';
import { API_ENDPOINTS } from '../config/api';

const RegisterForm = () => {
  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    email: '',
    password: '',
    password_confirmation: '',
    mobile: '',
    user_type: 'agent',
    role: 'agent_role',
    address: '',
    city: '',
    state: '',
    pan_number: '',
    gst_number: '',
    date_of_birth: '',
    gender: '',
    occupation: '',
    annual_income: ''
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(API_ENDPOINTS.REGISTER, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        // Registration successful
        console.log('Registration successful:', data);

        // Store token in localStorage
        localStorage.setItem('authToken', data.data.token);
        localStorage.setItem('user', JSON.stringify(data.data.user));

        // Redirect to dashboard or login
        // history.push('/dashboard');
      } else {
        // Registration failed
        setError(data.message || 'Registration failed');
      }
    } catch (err) {
      setError('Network error. Please try again.');
      console.error('Registration error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {error && <div className="error-message">{error}</div>}

      <div>
        <input
          type="text"
          placeholder="First Name"
          value={formData.first_name}
          onChange={(e) => setFormData({...formData, first_name: e.target.value})}
          required
        />
      </div>

      <div>
        <input
          type="text"
          placeholder="Last Name"
          value={formData.last_name}
          onChange={(e) => setFormData({...formData, last_name: e.target.value})}
          required
        />
      </div>

      <div>
        <input
          type="email"
          placeholder="Email"
          value={formData.email}
          onChange={(e) => setFormData({...formData, email: e.target.value})}
          required
        />
      </div>

      <div>
        <input
          type="password"
          placeholder="Password"
          value={formData.password}
          onChange={(e) => setFormData({...formData, password: e.target.value})}
          required
          minLength="6"
        />
      </div>

      <div>
        <input
          type="password"
          placeholder="Confirm Password"
          value={formData.password_confirmation}
          onChange={(e) => setFormData({...formData, password_confirmation: e.target.value})}
          required
        />
      </div>

      <div>
        <input
          type="tel"
          placeholder="Mobile Number"
          value={formData.mobile}
          onChange={(e) => setFormData({...formData, mobile: e.target.value})}
          required
          pattern="[0-9]{10}"
        />
      </div>

      <button type="submit" disabled={loading}>
        {loading ? 'Registering...' : 'Register'}
      </button>
    </form>
  );
};

export default RegisterForm;
```

### Using Axios (Alternative)

```jsx
import axios from 'axios';

const registerUser = async (userData) => {
  try {
    const response = await axios.post(API_ENDPOINTS.REGISTER, userData, {
      headers: {
        'Content-Type': 'application/json',
      }
    });

    if (response.data.success) {
      localStorage.setItem('authToken', response.data.data.token);
      localStorage.setItem('user', JSON.stringify(response.data.data.user));
      return { success: true, data: response.data.data };
    } else {
      return { success: false, error: response.data.message };
    }
  } catch (error) {
    if (error.response && error.response.data) {
      return { success: false, error: error.response.data.message, errors: error.response.data.errors };
    }
    return { success: false, error: 'Network error occurred' };
  }
};
```

## 2. User Login API

### React Component Example

```jsx
import React, { useState } from 'react';
import { API_ENDPOINTS } from '../config/api';

const LoginForm = () => {
  const [credentials, setCredentials] = useState({
    email: '',
    password: ''
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(API_ENDPOINTS.LOGIN, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(credentials)
      });

      const data = await response.json();

      if (data.success) {
        // Login successful
        console.log('Login successful:', data);

        // Store token and user data
        localStorage.setItem('authToken', data.data.token);
        localStorage.setItem('user', JSON.stringify(data.data.user));
        localStorage.setItem('tokenExpiry', data.data.exp);

        // Redirect to dashboard
        // history.push('/dashboard');

        return { success: true, user: data.data.user };
      } else {
        // Login failed
        setError(data.message || 'Login failed');
        return { success: false, error: data.message };
      }
    } catch (err) {
      setError('Network error. Please try again.');
      console.error('Login error:', err);
      return { success: false, error: 'Network error occurred' };
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {error && <div className="error-message">{error}</div>}

      <div>
        <input
          type="email"
          placeholder="Email"
          value={credentials.email}
          onChange={(e) => setCredentials({...credentials, email: e.target.value})}
          required
        />
      </div>

      <div>
        <input
          type="password"
          placeholder="Password"
          value={credentials.password}
          onChange={(e) => setCredentials({...credentials, password: e.target.value})}
          required
        />
      </div>

      <button type="submit" disabled={loading}>
        {loading ? 'Signing in...' : 'Sign In'}
      </button>
    </form>
  );
};

export default LoginForm;
```

### Using Axios (Alternative)

```jsx
import axios from 'axios';

const loginUser = async (email, password) => {
  try {
    const response = await axios.post(API_ENDPOINTS.LOGIN, {
      email,
      password
    });

    if (response.data.success) {
      localStorage.setItem('authToken', response.data.data.token);
      localStorage.setItem('user', JSON.stringify(response.data.data.user));
      localStorage.setItem('tokenExpiry', response.data.data.exp);
      return { success: true, data: response.data.data };
    } else {
      return { success: false, error: response.data.message };
    }
  } catch (error) {
    if (error.response && error.response.data) {
      return { success: false, error: error.response.data.message };
    }
    return { success: false, error: 'Network error occurred' };
  }
};
```

## 3. Authentication Context (React Context API)

```jsx
// contexts/AuthContext.js
import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { API_ENDPOINTS } from '../config/api';

const AuthContext = createContext();

const authReducer = (state, action) => {
  switch (action.type) {
    case 'LOGIN_START':
      return { ...state, loading: true, error: null };
    case 'LOGIN_SUCCESS':
      return {
        ...state,
        loading: false,
        isAuthenticated: true,
        user: action.payload.user,
        token: action.payload.token
      };
    case 'LOGIN_FAILURE':
      return {
        ...state,
        loading: false,
        error: action.payload,
        isAuthenticated: false
      };
    case 'LOGOUT':
      return {
        ...state,
        isAuthenticated: false,
        user: null,
        token: null
      };
    default:
      return state;
  }
};

const initialState = {
  isAuthenticated: false,
  user: null,
  token: localStorage.getItem('authToken'),
  loading: false,
  error: null
};

export const AuthProvider = ({ children }) => {
  const [state, dispatch] = useReducer(authReducer, initialState);

  useEffect(() => {
    const token = localStorage.getItem('authToken');
    const user = localStorage.getItem('user');

    if (token && user) {
      dispatch({
        type: 'LOGIN_SUCCESS',
        payload: {
          token,
          user: JSON.parse(user)
        }
      });
    }
  }, []);

  const login = async (email, password) => {
    dispatch({ type: 'LOGIN_START' });

    try {
      const response = await fetch(API_ENDPOINTS.LOGIN, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();

      if (data.success) {
        localStorage.setItem('authToken', data.data.token);
        localStorage.setItem('user', JSON.stringify(data.data.user));

        dispatch({
          type: 'LOGIN_SUCCESS',
          payload: {
            token: data.data.token,
            user: data.data.user
          }
        });

        return { success: true };
      } else {
        dispatch({
          type: 'LOGIN_FAILURE',
          payload: data.message
        });
        return { success: false, error: data.message };
      }
    } catch (error) {
      dispatch({
        type: 'LOGIN_FAILURE',
        payload: 'Network error occurred'
      });
      return { success: false, error: 'Network error occurred' };
    }
  };

  const register = async (userData) => {
    dispatch({ type: 'LOGIN_START' });

    try {
      const response = await fetch(API_ENDPOINTS.REGISTER, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(userData)
      });

      const data = await response.json();

      if (data.success) {
        localStorage.setItem('authToken', data.data.token);
        localStorage.setItem('user', JSON.stringify(data.data.user));

        dispatch({
          type: 'LOGIN_SUCCESS',
          payload: {
            token: data.data.token,
            user: data.data.user
          }
        });

        return { success: true };
      } else {
        dispatch({
          type: 'LOGIN_FAILURE',
          payload: data.message
        });
        return { success: false, error: data.message, errors: data.errors };
      }
    } catch (error) {
      dispatch({
        type: 'LOGIN_FAILURE',
        payload: 'Network error occurred'
      });
      return { success: false, error: 'Network error occurred' };
    }
  };

  const logout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    localStorage.removeItem('tokenExpiry');
    dispatch({ type: 'LOGOUT' });
  };

  return (
    <AuthContext.Provider value={{
      ...state,
      login,
      register,
      logout
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
```

## 4. API Service (Centralized)

```javascript
// services/authService.js
import { API_ENDPOINTS } from '../config/api';

class AuthService {
  async register(userData) {
    try {
      const response = await fetch(API_ENDPOINTS.REGISTER, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(userData)
      });

      const data = await response.json();

      if (data.success) {
        this.setAuthData(data.data);
        return { success: true, data: data.data };
      } else {
        return { success: false, error: data.message, errors: data.errors };
      }
    } catch (error) {
      return { success: false, error: 'Network error occurred' };
    }
  }

  async login(email, password) {
    try {
      const response = await fetch(API_ENDPOINTS.LOGIN, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();

      if (data.success) {
        this.setAuthData(data.data);
        return { success: true, data: data.data };
      } else {
        return { success: false, error: data.message };
      }
    } catch (error) {
      return { success: false, error: 'Network error occurred' };
    }
  }

  setAuthData(authData) {
    localStorage.setItem('authToken', authData.token);
    localStorage.setItem('user', JSON.stringify(authData.user));
    localStorage.setItem('tokenExpiry', authData.exp);
  }

  getAuthToken() {
    return localStorage.getItem('authToken');
  }

  getUser() {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  }

  isAuthenticated() {
    const token = this.getAuthToken();
    return !!token;
  }

  logout() {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    localStorage.removeItem('tokenExpiry');
  }
}

export default new AuthService();
```

## 5. Protected Route Component

```jsx
// components/ProtectedRoute.js
import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return <div>Loading...</div>; // Or your loading component
  }

  return isAuthenticated ? children : <Navigate to="/login" />;
};

export default ProtectedRoute;
```

## 6. Usage in App.js

```jsx
// App.js
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import LoginForm from './components/LoginForm';
import RegisterForm from './components/RegisterForm';
import Dashboard from './components/Dashboard';
import ProtectedRoute from './components/ProtectedRoute';

function App() {
  return (
    <Router>
      <AuthProvider>
        <div className="App">
          <Routes>
            <Route path="/login" element={<LoginForm />} />
            <Route path="/register" element={<RegisterForm />} />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }
            />
            <Route path="/" element={<Navigate to="/dashboard" />} />
          </Routes>
        </div>
      </AuthProvider>
    </Router>
  );
}

export default App;
```

## 7. Environment Variables

Create a `.env` file in your React app root:

```env
# .env
REACT_APP_API_BASE_URL=http://localhost:3000/api/v1
REACT_APP_PRODUCTION_API_URL=https://your-production-domain.onrender.com/api/v1
```

## 8. API Response Examples

### Successful Registration Response:
```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3NjMzODg3MDB9.d2tQlNGn_Dxng-Qlrpf6XjcLD4CHxkHfgUSnVGO7bk0",
    "exp": "11-17-2025 14:11",
    "user": {
      "id": 1,
      "first_name": "Test",
      "last_name": "User",
      "full_name": "Test User",
      "email": "test@example.com",
      "mobile": "9876543210",
      "user_type": "agent",
      "role": "agent_role",
      "status": true,
      "created_at": "2025-11-16T14:11:40.064Z",
      "updated_at": "2025-11-16T14:11:40.064Z"
    }
  }
}
```

### Successful Login Response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3NjMzODg3MDl9.W6OQ-H7A3MJ52Cj2V2TXtA8lcKjgEuhvcwHgAi2xYKY",
    "exp": "11-17-2025 14:11",
    "user": {
      "id": 1,
      "first_name": "Test",
      "last_name": "User",
      "full_name": "Test User",
      "email": "test@example.com",
      "mobile": "9876543210",
      "user_type": "agent",
      "role": "agent_role",
      "status": true
    }
  }
}
```

### Error Responses:
```json
{
  "success": false,
  "message": "Invalid credentials"
}

{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 6 characters)"
  ]
}
```

## 9. Key Points

- **CORS**: Make sure your Rails API has CORS configured properly for your React app domain
- **Token Storage**: Store JWT tokens securely (consider using httpOnly cookies for production)
- **Token Expiry**: Tokens expire after 24 hours. Implement token refresh or redirect to login
- **Error Handling**: Always handle network errors and API error responses
- **Loading States**: Show loading indicators during API calls
- **Validation**: Implement client-side validation matching server-side requirements

This documentation provides everything you need to integrate the InsureBook authentication APIs with your React application!