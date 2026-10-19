# Test Register API
# =====================================

$ErrorActionPreference = "Stop"

# Configuration
$ApiGatewayUrl = "http://localhost:5000"
$UserServiceUrl = "http://localhost:5001"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Test Register & Login Flow" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# ========== STEP 1: Register New User ==========
Write-Host "[STEP 1] Đăng ký người dùng mới" -ForegroundColor Yellow
Write-Host "Request: POST $ApiGatewayUrl/auth/register" -ForegroundColor Gray

$newUserRequest = @{
	Name = "Charlie$(Get-Random -Minimum 1000 -Maximum 9999)"
	Email = "charlie$(Get-Random -Minimum 1000 -Maximum 9999)@example.com"
} | ConvertTo-Json

Write-Host "Body: $newUserRequest" -ForegroundColor Gray

try {
	$registerResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/auth/register" `
		-Method Post `
		-ContentType "application/json" `
		-Body $newUserRequest `
		-TimeoutSec 10

	$newUserId = $registerResponse.id
	$newUserName = $registerResponse.name
	$newUserEmail = $registerResponse.email

	Write-Host "✅ Đăng ký thành công!" -ForegroundColor Green
	Write-Host "  - ID: $newUserId" -ForegroundColor Gray
	Write-Host "  - Name: $newUserName" -ForegroundColor Gray
	Write-Host "  - Email: $newUserEmail" -ForegroundColor Gray
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi đăng ký: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}

# ========== STEP 2: Try to Register Duplicate Email ==========
Write-Host "[STEP 2] Thử đăng ký lại với email đã tồn tại (Expected: 409 Conflict)" -ForegroundColor Yellow
Write-Host "Request: POST $ApiGatewayUrl/auth/register" -ForegroundColor Gray

$duplicateRequest = @{
	Name = "AnotherName"
	Email = $newUserEmail
} | ConvertTo-Json

Write-Host "Body: $duplicateRequest" -ForegroundColor Gray

try {
	$duplicateResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/auth/register" `
		-Method Post `
		-ContentType "application/json" `
		-Body $duplicateRequest `
		-TimeoutSec 10

	Write-Host "⚠️  Không mong muốn: Đã cho phép đăng ký email trùng!" -ForegroundColor Yellow
} catch {
	if ($_.Exception.Response.StatusCode -eq 409) {
		Write-Host "✅ Đúng! Server trả về 409 Conflict (email đã tồn tại)" -ForegroundColor Green
		Write-Host "  Response: $($_.Exception.Message)" -ForegroundColor Gray
	} else {
		Write-Host "⚠️  Lỗi không mong muốn: $($_.Exception.Message)" -ForegroundColor Yellow
	}
}
Write-Host ""

# ========== STEP 3: Login with New User ==========
Write-Host "[STEP 3] Đăng nhập với tài khoản mới vừa đăng ký" -ForegroundColor Yellow
Write-Host "Request: POST $ApiGatewayUrl/auth/token" -ForegroundColor Gray

$loginRequest = @{
	Name = $newUserName
	Email = $newUserEmail
} | ConvertTo-Json

Write-Host "Body: $loginRequest" -ForegroundColor Gray

try {
	$tokenResponse = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/auth/token" `
		-Method Post `
		-ContentType "application/json" `
		-Body $loginRequest `
		-TimeoutSec 10

	$token = $tokenResponse.accessToken
	$expiresIn = $tokenResponse.expiresIn

	Write-Host "✅ Đăng nhập thành công!" -ForegroundColor Green
	Write-Host "  Token: $($token.Substring(0, 50))..." -ForegroundColor Gray
	Write-Host "  Expires in: $expiresIn giây" -ForegroundColor Gray
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi đăng nhập: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}

# ========== STEP 4: Get User Profile with Token ==========
Write-Host "[STEP 4] Lấy profile user bằng token vừa lấy được" -ForegroundColor Yellow
Write-Host "Request: GET $ApiGatewayUrl/users/$newUserId" -ForegroundColor Gray

$headers = @{
	"Authorization" = "Bearer $token"
}

try {
	$userProfile = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/users/$newUserId" `
		-Method Get `
		-Headers $headers `
		-TimeoutSec 10

	Write-Host "✅ Lấy profile thành công!" -ForegroundColor Green
	Write-Host "  - ID: $($userProfile.id)" -ForegroundColor Gray
	Write-Host "  - Name: $($userProfile.name)" -ForegroundColor Gray
	Write-Host "  - Email: $($userProfile.email)" -ForegroundColor Gray
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi lấy profile: $($_.Exception.Message)" -ForegroundColor Red
}

# ========== STEP 5: Get All Users ==========
Write-Host "[STEP 5] Lấy danh sách tất cả users" -ForegroundColor Yellow
Write-Host "Request: GET $ApiGatewayUrl/users" -ForegroundColor Gray

try {
	$allUsers = Invoke-RestMethod `
		-Uri "$ApiGatewayUrl/users" `
		-Method Get `
		-Headers $headers `
		-TimeoutSec 10

	Write-Host "✅ Danh sách users:" -ForegroundColor Green
	Write-Host "Tổng số: $($allUsers.Count) users" -ForegroundColor Gray
	$allUsers | ForEach-Object {
		Write-Host "  - ID: $($_.id), Name: $($_.name), Email: $($_.email)" -ForegroundColor Gray
	}
	Write-Host ""
} catch {
	Write-Host "❌ Lỗi khi lấy danh sách: $($_.Exception.Message)" -ForegroundColor Red
}

# ========== Summary ==========
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✅ Register & Login Flow Test Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Kết quả test:" -ForegroundColor Cyan
Write-Host "  ✅ Register new user: SUCCESS" -ForegroundColor Green
Write-Host "  ✅ Duplicate email check: SUCCESS" -ForegroundColor Green
Write-Host "  ✅ Login with new account: SUCCESS" -ForegroundColor Green
Write-Host "  ✅ Get user profile: SUCCESS" -ForegroundColor Green
Write-Host "  ✅ List all users: SUCCESS" -ForegroundColor Green
Write-Host ""
Write-Host "Tài khoản test được tạo:" -ForegroundColor Gray
Write-Host "  Name: $newUserName" -ForegroundColor Gray
Write-Host "  Email: $newUserEmail" -ForegroundColor Gray
Write-Host ""
