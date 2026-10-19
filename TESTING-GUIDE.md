# 📋 Hướng dẫn Test Luồng Request qua API Gateway
## Mục tiêu: Kiểm tra request đi qua Ocelot Gateway tới các Microservices

---

## 🚀 Cách 1: Dùng PowerShell Script (Được khuyến nghị)

### 📌 Bước 1: Chuẩn bị
1. Đảm bảo tất cả services đang chạy:
   - **ApiGateway**: http://localhost:5000
   - **UserService**: http://localhost:5001
   - **ProductService**: http://localhost:5002

2. Mở PowerShell tại thư mục solution

### 📌 Bước 2: Chạy script

```powershell
# Chạy script test
.\Test-Gateway-Flow.ps1
```

### 📌 Kết quả mong đợi:

```
✅ Token lấy được thành công!
✅ Danh sách users lấy được từ gateway!
✅ Danh sách products lấy được từ gateway!
```

**Luồng request sẽ:**
1. `POST /auth/token` → Gateway → UserService (Auth)
2. `GET /users` → Gateway → UserService
3. `GET /products` → Gateway → ProductService
4. `GET /products/1` → Gateway → ProductService → (ProductService gọi UserService để lấy creator info)

---

## 🎯 Cách 2: Dùng Postman/Insomnia

### 📌 Import Collection

1. Mở **Postman** hoặc **Insomnia**
2. Click **Import** 
3. Chọn file `Test-Gateway-Flow.postman_collection.json`
4. Collection sẽ được import với tất cả các API requests

### 📌 Setup Environment Variables

Trong Postman/Insomnia, tạo Environment với 2 variables:

| Variable | Value |
|----------|-------|
| `gateway_url` | http://localhost:5000 |
| `token` | (sẽ được tự động fill sau khi chạy request 1) |

### 📌 Chạy requests theo thứ tự

**Phải chạy theo thứ tự này:**

1. ✅ **"1. GET TOKEN (via Gateway)"** - Lấy JWT Token
   - **URL**: `http://localhost:5000/auth/token`
   - **Method**: POST
   - **Body**: 
	 ```json
	 {
	   "name": "Alice",
	   "email": "alice@example.com"
	 }
	 ```
   - Token sẽ được tự động lưu vào environment

2. ✅ **"2. GET All Users (via Gateway)"** - Lấy danh sách users
   - **URL**: `http://localhost:5000/users`
   - **Method**: GET
   - Token sẽ tự động được thêm vào header

3. ✅ **"3. GET User by ID (via Gateway)"** - Lấy user cụ thể

4. ✅ **"7. GET All Products (via Gateway)"** - Lấy danh sách products

5. ✅ **"8. GET Product by ID (via Gateway)"** - Lấy product cụ thể
   - Lưu ý: Phản hồi sẽ bao gồm creator info (ProductService gọi UserService)

### 📌 Testing Endpoints

```
🔐 Toàn bộ endpoints (trừ /auth/token) cần JWT Token trong header:

Authorization: Bearer <token>
```

---

## 🧪 Cách 3: Dùng cURL (Command Line)

### 📌 Bước 1: Lấy Token

```bash
curl -X POST http://localhost:5000/auth/token \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'
```

**Phản hồi:**
```json
{
  "accessToken": "eyJhbGc...",
  "expiresIn": 7200
}
```

### 📌 Bước 2: Copy token và sử dụng

```bash
# Set biến token
$token = "eyJhbGc..."

# GET Users (qua Gateway)
curl -X GET http://localhost:5000/users \
  -H "Authorization: Bearer $token"

# GET Products (qua Gateway)
curl -X GET http://localhost:5000/products \
  -H "Authorization: Bearer $token"

# GET Product by ID (service-to-service gọi)
curl -X GET http://localhost:5000/products/1 \
  -H "Authorization: Bearer $token"
```

---

## 📊 Luồng Chi Tiết

### Request 1: Authenticate (Public endpoint - không cần token)
```
Client
  ↓
[POST /auth/token] ← API Gateway
  ↓
[UserService: POST /auth/token]
  ↓
Response: JWT Token
```

### Request 2: Get Users (Requires JWT)
```
Client + JWT Token
  ↓
[GET /users] ← API Gateway
  ↓
[UserService: GET /users] ← Ocelot forwards request
  ↓
Response: User List
```

### Request 3: Get Products with Creator Info (Inter-service call)
```
Client + JWT Token
  ↓
[GET /products/1] ← API Gateway
  ↓
[ProductService: GET /products/1]
  ↓
ProductService cần creator info → [UserService: GET /users/1]
  ↓
ProductService returns ProductDto + UserBriefDto
```

### Direct call (không qua Gateway)
```
Client + JWT Token  
  ↓
Direct to UserService:5001/users
  (Bypass Gateway completely)
```

---

## ⚙️ Ocelot Configuration (ocelot.json)

```json
{
  "Routes": [
	{
	  "UpstreamPathTemplate": "/users/{everything}",
	  "DownstreamPathTemplate": "/users/{everything}",
	  "DownstreamHostAndPorts": [{ "Host": "localhost", "Port": 5001 }],
	  "AuthenticationOptions": { "AuthenticationProviderKey": "Bearer" }
	},
	{
	  "UpstreamPathTemplate": "/products/{everything}",
	  "DownstreamPathTemplate": "/products/{everything}",
	  "DownstreamHostAndPorts": [{ "Host": "localhost", "Port": 5002 }],
	  "AuthenticationOptions": { "AuthenticationProviderKey": "Bearer" }
	},
	{
	  "UpstreamPathTemplate": "/auth/{everything}",
	  "DownstreamPathTemplate": "/auth/{everything}",
	  "DownstreamHostAndPorts": [{ "Host": "localhost", "Port": 5001 }]
	}
  ]
}
```

### Giải thích:
- `/users/*` → Gateway chuyển tiếp tới UserService (5001)
- `/products/*` → Gateway chuyển tiếp tới ProductService (5002)
- `/auth/*` → Gateway chuyển tiếp tới UserService (5001)
- Tất cả `/users` và `/products` routes yêu cầu JWT authentication

---

## 🔍 Debugging Tips

### 1. Kiểm tra Gateway logs
- Mở Visual Studio Output window
- Chọn "ApiGateway" trong dropdown
- Xem request/response logs

### 2. Kiểm tra Service logs
- Tương tự cho UserService và ProductService

### 3. Kiểm tra Swagger UI
- Gateway: http://localhost:5000/swagger/index.html
- UserService: http://localhost:5001/swagger/index.html
- ProductService: http://localhost:5002/swagger/index.html
- Tại đây bạn có thể test các endpoints trực tiếp

### 4. Test với invalid token
```bash
curl -X GET http://localhost:5000/users \
  -H "Authorization: Bearer invalid_token"
# Expected: 401 Unauthorized
```

### 5. Test endpoint không yêu cầu auth (/auth/token)
```bash
curl -X POST http://localhost:5000/auth/token \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com"}'
# Không cần token trong header
```

---

## ✅ Checklist Verification

- [ ] ApiGateway khởi động thành công (port 5000)
- [ ] UserService khởi động thành công (port 5001)
- [ ] ProductService khởi động thành công (port 5002)
- [ ] Lấy token qua gateway `/auth/token`
- [ ] Gọi `/users` qua gateway thành công
- [ ] Gọi `/products` qua gateway thành công
- [ ] Gọi `/products/1` và nhận được creator info (service-to-service)
- [ ] Xác thực JWT token không hợp lệ -> 401
- [ ] Truy cập Swagger UI ở mỗi service

---

## 📝 Ghi chú

- **Port 5000**: API Gateway (Ocelot)
- **Port 5001**: UserService
- **Port 5002**: ProductService
- **JWT Token**: Hết hạn sau 120 phút (mặc định)
- **Service-to-service**: ProductService gọi UserService để lấy creator info (Polly retry policy)

---

## 🎓 Kết luận

Test này chứng minh:
1. ✅ API Gateway (Ocelot) đang route request đúng
2. ✅ JWT authentication hoạt động qua gateway
3. ✅ Microservices có thể gọi lẫn nhau (inter-service communication)
4. ✅ Data aggregation hoạt động (Product + Creator info)

