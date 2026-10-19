# 🚀 Test Gateway Flow - README

## 📦 Các file testing đã được tạo

| File | Mô tả |
|------|-------|
| `Test-Gateway-Flow.ps1` | PowerShell script để test (Windows) |
| `Test-Gateway-Flow.sh` | Bash script để test (Linux/Mac) |
| `Test-Gateway-Flow.postman_collection.json` | Postman Collection |
| `TESTING-GUIDE.md` | Hướng dẫn chi tiết |

---

## ⚡ Quick Start

### 🪟 Windows (PowerShell)

```powershell
# Chạy ngay lập tức
.\Test-Gateway-Flow.ps1
```

### 🐧 Linux/Mac

```bash
# Cấp quyền cho script
chmod +x Test-Gateway-Flow.sh

# Chạy script
./Test-Gateway-Flow.sh
```

### 🔌 Postman/Insomnia

1. Mở Postman/Insomnia
2. **Import** → Chọn `Test-Gateway-Flow.postman_collection.json`
3. Chạy requests theo thứ tự (bắt đầu từ "GET TOKEN")

---

## 🎯 Luồng Test

```
1️⃣ Authenticate
   └─ POST /auth/token (không cần JWT)
	  └─ Lấy JWT Token

2️⃣ Gateway → UserService (/users)
   └─ GET /users (qua gateway:5000)
	  └─ Route tới UserService:5001
	  └─ Cần JWT Token

3️⃣ Gateway → ProductService (/products)
   └─ GET /products (qua gateway:5000)
	  └─ Route tới ProductService:5002
	  └─ Cần JWT Token

4️⃣ Service-to-Service Communication
   └─ GET /products/1 (qua gateway:5000)
	  └─ Route tới ProductService:5002
	  └─ ProductService gọi UserService:5001 để lấy creator info
	  └─ Kết quả: Product + Creator Info
```

---

## 📊 Dữ liệu Test

### Seed Data

**UserService** (seeded khi khởi động):
```
ID | Name  | Email
---|-------|--------------------
1  | Alice | alice@example.com
2  | Bob   | bob@example.com
```

**ProductService** (seeded khi khởi động):
```
ID | Name    | Price  | Quantity | CreatedByUserId
---|---------|--------|----------|----------------
1  | Keyboard| 49.99  | 100      | 1
2  | Mouse   | 25.00  | 200      | 2
```

### Credentials đã seeded
```
Name: Alice
Email: alice@example.com
```

---

## 🔍 Kỳ vọng kết quả

### Step 1: GET TOKEN
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 7200
}
```

### Step 2: GET Users
```json
[
  {
	"id": 1,
	"name": "Alice",
	"email": "alice@example.com"
  },
  {
	"id": 2,
	"name": "Bob",
	"email": "bob@example.com"
  }
]
```

### Step 3: GET Products
```json
[
  {
	"id": 1,
	"name": "Keyboard",
	"price": 49.99,
	"quantity": 100,
	"createdByUserId": 1,
	"creator": {
	  "id": 1,
	  "name": "Alice",
	  "email": "alice@example.com"
	}
  },
  ...
]
```

---

## 🚨 Troubleshooting

### ❌ "Connection refused"
**Giải pháp**: Đảm bảo tất cả 3 services đang chạy
```
✅ ApiGateway: http://localhost:5000
✅ UserService: http://localhost:5001
✅ ProductService: http://localhost:5002
```

### ❌ "401 Unauthorized"
**Giải pháp**: JWT Token không hợp lệ hoặc hết hạn
- Chạy Step 1 lại để lấy token mới
- Đảm bảo token được pass đúng trong header: `Authorization: Bearer <token>`

### ❌ "404 Not Found"
**Giải pháp**: Kiểm tra ocelot.json route configuration
- Đảm bảo routes được configure đúng
- Kiểm tra port của downstream services

### ❌ Script không chạy được
**PowerShell**:
```powershell
# Cập nhật execution policy (nếu cần)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Bash**:
```bash
# Cấp quyền execute
chmod +x Test-Gateway-Flow.sh
```

---

## 📝 Chi tiết từng endpoint

### 🔓 Public Endpoints (không cần JWT)
```
POST /auth/token
  - Body: { "name": "Alice", "email": "alice@example.com" }
  - Response: { "accessToken": "...", "expiresIn": 7200 }
```

### 🔐 Protected Endpoints (cần JWT)
```
GET /users
  - Header: Authorization: Bearer <token>
  - Response: List of Users[]

GET /users/{id}
  - Header: Authorization: Bearer <token>
  - Response: User

POST /users
  - Header: Authorization: Bearer <token>
  - Body: { "name": "...", "email": "..." }
  - Response: User (201 Created)

PUT /users/{id}
  - Header: Authorization: Bearer <token>
  - Body: { "name": "...", "email": "..." }
  - Response: 204 No Content

DELETE /users/{id}
  - Header: Authorization: Bearer <token>
  - Response: 204 No Content
```

```
GET /products
  - Header: Authorization: Bearer <token>
  - Response: List of Products[] (with Creator info)

GET /products/{id}
  - Header: Authorization: Bearer <token>
  - Response: Product (with Creator info)

POST /products
  - Header: Authorization: Bearer <token>
  - Body: { "name": "...", "price": 0.00, "quantity": 0, "createdByUserId": 1 }
  - Response: Product (201 Created)

PUT /products/{id}
  - Header: Authorization: Bearer <token>
  - Body: { "name": "...", "price": 0.00, "quantity": 0 }
  - Response: 204 No Content

DELETE /products/{id}
  - Header: Authorization: Bearer <token>
  - Response: 204 No Content
```

---

## 🧪 Advanced Testing

### Test với Invalid Token
```bash
curl -X GET http://localhost:5000/users \
  -H "Authorization: Bearer invalid_token_here"

# Expected: 401 Unauthorized
```

### Test với Token hết hạn
1. Lấy token
2. Đợi (hoặc chỉnh lại ExpiresMinutes trong config)
3. Sử dụng token đã hết hạn
4. Expect: 401 Unauthorized

### Test trực tiếp Service (bypass Gateway)
```bash
# UserService trực tiếp (BYPASS Gateway)
curl -X GET http://localhost:5001/users \
  -H "Authorization: Bearer <token>"

# ProductService trực tiếp (BYPASS Gateway)
curl -X GET http://localhost:5002/products \
  -H "Authorization: Bearer <token>"
```

---

## 🎓 Học hỏi từ test này

1. **API Gateway Pattern**: Ocelot route requests đúng cách
2. **Microservices Communication**: Service-to-service calls hoạt động
3. **JWT Authentication**: Security được enforce
4. **Cross-service Data Aggregation**: ProductService gọi UserService
5. **Service Discovery**: Docker Compose network hoạt động (khi deploy)

---

## 📞 Support

Nếu có vấn đề:
1. Kiểm tra tất cả services đang chạy
2. Kiểm tra output logs từ Visual Studio
3. Verify JWT token hợp lệ (không hết hạn)
4. Kiểm tra network connectivity giữa services

---

## ✨ Summary

| Aspect | Status |
|--------|--------|
| API Gateway Routing | ✅ Ready |
| Authentication | ✅ Ready |
| User Service | ✅ Ready |
| Product Service | ✅ Ready |
| Testing Scripts | ✅ Ready |
| Documentation | ✅ Ready |

🎉 **Bạn đã sẵn sàng test hệ thống microservices!**

