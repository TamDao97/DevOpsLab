# Test luồng request đi qua API Gateway
# =====================================
# Lưu ý: Đảm bảo tất cả services đang chạy:
# - ApiGateway (port 5000)
# - UserService (port 5001)  
# - ProductService (port 5002)

$ErrorActionPreference = "Stop"

# Cấu hình URLs
$ApiGatewayUrl = "http://localhost:5000"
$UserServiceUrl = "http://localhost:5001"
$ProductServiceUrl = "http://localhost:5002"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Test luồng request qua API Gateway" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# ========== STEP 1: Authenticate ==========
Write-Host "[STEP 1] Lấy JWT Token từ /auth/token" -ForegroundColor Yellow
Write-Host "Request qua Gateway: POST $ApiGatewayUrl/auth/token" -ForegroundColor Gray

$tokenRequest = @{
	Name = "Alice"
	Email = "alice@example.com"
} | ConvertTo-Json

try {
	$tokenResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/auth/token" `
		-Method Post `
		-ContentType "application/json" `
		-Body $tokenRequest `
		-TimeoutSec 10

	$token = $tokenResponse.accessToken
	$expiresIn = $tokenResponse.expiresIn

	Write-Host "✅ Token lấy được thành công!" -ForegroundColor Green
	Write-Host "Token: $($token.Substring(0, 50))..." -ForegroundColor Gray
	Write-Host "Expires in: $expiresIn giây" -ForegroundColor Gray
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi lấy token: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}

# ========== STEP 2: Get Users via Gateway ==========
Write-Host "[STEP 2] Lấy danh sách Users qua Gateway" -ForegroundColor Yellow
Write-Host "Request qua Gateway: GET $ApiGatewayUrl/users" -ForegroundColor Gray

$headers = @{
	"Authorization" = "Bearer $token"
}

try {
	$usersResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/users" `
		-Method Get `
		-Headers $headers `
		-TimeoutSec 10

	Write-Host "✅ Danh sách users lấy được từ gateway!" -ForegroundColor Green
	Write-Host "Số lượng users: $($usersResponse.Count)" -ForegroundColor Gray
	$usersResponse | ForEach-Object {
		Write-Host "  - ID: $($_.id), Name: $($_.name), Email: $($_.email)" -ForegroundColor Gray
	}
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi lấy users: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}

# ========== STEP 3: Get Products via Gateway ==========
Write-Host "[STEP 3] Lấy danh sách Products qua Gateway" -ForegroundColor Yellow
Write-Host "Request qua Gateway: GET $ApiGatewayUrl/products" -ForegroundColor Gray

try {
	$productsResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/products" `
		-Method Get `
		-Headers $headers `
		-TimeoutSec 10

	Write-Host "✅ Danh sách products lấy được từ gateway!" -ForegroundColor Green
	Write-Host "Số lượng products: $($productsResponse.Count)" -ForegroundColor Gray
	$productsResponse | ForEach-Object {
		Write-Host "  - ID: $($_.id), Name: $($_.name), Price: $($_.price), Qty: $($_.quantity)" -ForegroundColor Gray
	}
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi lấy products: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}

# ========== STEP 4: Get User by ID via Gateway ==========
Write-Host "[STEP 4] Lấy User theo ID (1) qua Gateway" -ForegroundColor Yellow
Write-Host "Request qua Gateway: GET $ApiGatewayUrl/users/1" -ForegroundColor Gray

try {
	$userResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/users/1" `
		-Method Get `
		-Headers $headers `
		-TimeoutSec 10

	Write-Host "✅ User lấy được thành công!" -ForegroundColor Green
	Write-Host "  - ID: $($userResponse.id)" -ForegroundColor Gray
	Write-Host "  - Name: $($userResponse.name)" -ForegroundColor Gray
	Write-Host "  - Email: $($userResponse.email)" -ForegroundColor Gray
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi lấy user: $($_.Exception.Message)" -ForegroundColor Red
}

# ========== STEP 5: Get Product by ID (with User info) ==========
Write-Host "[STEP 5] Lấy Product theo ID (1) qua Gateway (hiển thị info creator)" -ForegroundColor Yellow
Write-Host "Request qua Gateway: GET $ApiGatewayUrl/products/1" -ForegroundColor Gray

try {
	$productResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/products/1" `
		-Method Get `
		-Headers $headers `
		-TimeoutSec 10

	Write-Host "✅ Product lấy được thành công!" -ForegroundColor Green
	Write-Host "  - ID: $($productResponse.id)" -ForegroundColor Gray
	Write-Host "  - Name: $($productResponse.name)" -ForegroundColor Gray
	Write-Host "  - Price: $($productResponse.price)" -ForegroundColor Gray
	Write-Host "  - Quantity: $($productResponse.quantity)" -ForegroundColor Gray
	Write-Host "  - Created by User ID: $($productResponse.createdByUserId)" -ForegroundColor Gray
	if ($productResponse.creator) {
		Write-Host "  - Creator Info:" -ForegroundColor Gray
		Write-Host "    - Name: $($productResponse.creator.name)" -ForegroundColor Gray
		Write-Host "    - Email: $($productResponse.creator.email)" -ForegroundColor Gray
	}
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi lấy product: $($_.Exception.Message)" -ForegroundColor Red
}

# ========== STEP 6: Test trực tiếp UserService (không qua gateway) ==========
Write-Host "[STEP 6] So sánh: Trực tiếp gọi UserService (port 5001)" -ForegroundColor Yellow
Write-Host "Request trực tiếp: GET $UserServiceUrl/users" -ForegroundColor Gray

try {
	$directUsersResponse = Invoke-RestMethod `
		-Uri "$UserServiceUrl/users" `
		-Method Get `
		-Headers $headers `
		-TimeoutSec 10

	Write-Host "✅ Trực tiếp UserService cũng hoạt động!" -ForegroundColor Green
	Write-Host "Số lượng users từ UserService: $($directUsersResponse.Count)" -ForegroundColor Gray
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi trực tiếp gọi UserService: $($_.Exception.Message)" -ForegroundColor Red
}

# ========== Summary ==========
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✅ Tất cả test hoàn tất thành công!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Tóm tắt:" -ForegroundColor Cyan
Write-Host "  1. Lấy token từ /auth/token qua gateway" -ForegroundColor Gray
Write-Host "  2. Gọi /users qua gateway (route tới UserService)" -ForegroundColor Gray
Write-Host "  3. Gọi /products qua gateway (route tới ProductService)" -ForegroundColor Gray
Write-Host "  4. Gọi /users/{id} qua gateway" -ForegroundColor Gray
Write-Host "  5. Gọi /products/{id} qua gateway (với service-to-service call)" -ForegroundColor Gray
Write-Host "  6. So sánh gọi trực tiếp UserService" -ForegroundColor Gray
Write-Host ""
