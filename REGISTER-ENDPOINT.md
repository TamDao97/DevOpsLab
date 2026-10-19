# 📝 API Register Documentation

## 🎯 Endpoint: POST /auth/register

**URL**: `http://localhost:5000/auth/register` (via Gateway)  
hoặc `http://localhost:5001/auth/register` (Direct UserService)

**Authentication**: ❌ NOT REQUIRED (Public endpoint)

**Status**: ✅ Created (201 Created)

---

## 📋 Request Body

```json
{
  "name": "Charlie",
  "email": "charlie@example.com"
}
```

### Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | Tên người dùng (không được empty) |
| `email` | string | Yes | Email người dùng (không được empty) |

---

## ✅ Success Response (201 Created)

**HTTP Status**: `201 Created`

```json
{
  "id": 3,
  "name": "Charlie",
  "email": "charlie@example.com"
}
```

---

## ❌ Error Responses

### 1️⃣ Missing Fields (400 Bad Request)
```
Status: 400
```
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "Bad Request",
  "status": 400,
  "detail": "Name & Email required"
}
```

### 2️⃣ Email Already Exists (409 Conflict)
```
Status: 409
```
```json
{
  "message": "Email 'charlie@example.com' đã được đăng ký"
}
```

### 3️⃣ Server Error (500 Internal Server Error)
```
Status: 500
```
```json
{
  "message": "Lỗi khi tạo user",
  "detail": "Error details..."
}
```

---

## 🧪 Test Examples

### PowerShell
```powershell
$body = @{
	name = "David"
	email = "david@example.com"
} | ConvertTo-Json

curl -X POST http://localhost:5000/auth/register `
  -H "Content-Type: application/json" `
  -Body $body
```

### cURL
```bash
curl -X POST http://localhost:5000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"David","email":"david@example.com"}'
```

### JavaScript/Axios
```javascript
const axios = require('axios');

const newUser = {
  name: 'David',
  email: 'david@example.com'
};

axios.post('http://localhost:5000/auth/register', newUser)
  .then(response => {
	console.log('User registered:', response.data);
  })
  .catch(error => {
	console.error('Registration failed:', error.response.data);
  });
```

### Postman
1. **Method**: POST
2. **URL**: `{{gateway_url}}/auth/register`
3. **Headers**: Content-Type: application/json
4. **Body** (raw JSON):
```json
{
  "name": "David",
  "email": "david@example.com"
}
```
5. Click **Send**

---

## 🔄 Typical Flow

### Step 1: Register
```
POST /auth/register
Body: {"name":"David","email":"david@example.com"}
Response: 201 Created - User object
```

### Step 2: Login with newly registered account
```
POST /auth/token
Body: {"name":"David","email":"david@example.com"}
Response: 200 OK - JWT Token
```

### Step 3: Use token to access protected endpoints
```
GET /users
Header: Authorization: Bearer <token>
Response: 200 OK - List of users
```

---

## 🛡️ Validation Rules

| Field | Rule | Example |
|-------|------|---------|
| Name | Non-empty string | "Charlie" ✅ |
| Email | Non-empty string | "charlie@example.com" ✅ |
| Email Uniqueness | Must be unique | Duplicate → 409 ❌ |

---

## 📊 HTTP Status Codes

| Code | Meaning | When |
|------|---------|------|
| 201 | Created | User successfully registered |
| 400 | Bad Request | Missing required fields |
| 409 | Conflict | Email already exists |
| 500 | Server Error | Database or other errors |

---

## 🔐 Security Notes

- ✅ Endpoint is **public** (no JWT required)
- ✅ Email **must be unique**
- ✅ Password is NOT implemented (can be added later)
- ✅ Input validation on name and email
- ✅ Returns created user info (not token)

---

## 🎯 Next Steps After Registration

After registering, user can:

1. **Get JWT Token**:
   ```
   POST /auth/token
   Body: {"name":"<name>","email":"<email>"}
   ```

2. **Access protected endpoints** with the token:
   ```
   GET /users
   Header: Authorization: Bearer <token>
   ```

3. **Update profile**:
   ```
   PUT /users/{id}
   Header: Authorization: Bearer <token>
   ```

---

## 📝 Test Script

Run the automated test:
```powershell
.\Test-Register-Login.ps1
```

This script will:
1. ✅ Register a new user
2. ✅ Try duplicate email (expect 409)
3. ✅ Login with new account
4. ✅ Get user profile
5. ✅ List all users

---

## 🖼️ Complete Registration Flow Diagram

```
┌─────────────────────────────────┐
│   Client Application            │
└────────────┬────────────────────┘
			 │
			 │ 1. POST /auth/register
			 │ {"name":"David","email":"david@example.com"}
			 │
			 ▼
┌─────────────────────────────────┐
│   API Gateway (Ocelot)          │
│   Port: 5000                    │
└────────────┬────────────────────┘
			 │
			 │ Route to UserService
			 │
			 ▼
┌─────────────────────────────────┐
│   UserService                   │
│   Post /auth/register           │
│   Port: 5001                    │
└────────────┬────────────────────┘
			 │
			 │ Check email exists
			 │ Create new User in DB
			 │
			 ▼
		✅ 201 Created
	{
	  "id": 3,
	  "name": "David",
	  "email": "david@example.com"
	}
			 │
			 ▼
┌─────────────────────────────────┐
│   Client receives User object   │
│   Can now login with this info  │
└─────────────────────────────────┘
```

---

## 💡 Use Cases

### New User Registration
```json
POST /auth/register
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

### Bulk Registration (multiple calls)
```bash
for i in {1..5}; do
  curl -X POST http://localhost:5000/auth/register \
	-H "Content-Type: application/json" \
	-d "{\"name\":\"User$i\",\"email\":\"user$i@example.com\"}"
done
```

### Validation before registration
```javascript
// Check if email format is valid
const isValidEmail = (email) => {
  return email.includes('@') && email.includes('.');
};

// Check if email already exists (optional API call)
const emailExists = async (email) => {
  const response = await axios.get(`/api/users?email=${email}`);
  return response.data.length > 0;
};
```

---

## 🚀 Deployment Notes

### Docker Compose
The endpoint will work in Docker:
```yaml
apigateway:5000/auth/register → userservice:8080/auth/register
```

### Testing in Production
```bash
curl -X POST https://api.example.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"User","email":"user@example.com"}'
```

---

