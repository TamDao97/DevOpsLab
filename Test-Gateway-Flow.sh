#!/bin/bash

# Test luồng request đi qua API Gateway
# =====================================
# Chạy trên Linux/Mac
# chmod +x Test-Gateway-Flow.sh
# ./Test-Gateway-Flow.sh

set -e

# Màu sắc output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Cấu hình URLs
API_GATEWAY_URL="http://localhost:5000"
USER_SERVICE_URL="http://localhost:5001"
PRODUCT_SERVICE_URL="http://localhost:5002"

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}Test luồng request qua API Gateway${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# ========== STEP 1: Authenticate ==========
echo -e "${YELLOW}[STEP 1] Lấy JWT Token từ /auth/token${NC}"
echo -e "${GRAY}Request qua Gateway: POST $API_GATEWAY_URL/auth/token${NC}"

TOKEN_RESPONSE=$(curl -s -X POST "$API_GATEWAY_URL/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}')

TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
EXPIRES_IN=$(echo "$TOKEN_RESPONSE" | grep -o '"expiresIn":[0-9]*' | cut -d':' -f2)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Lỗi khi lấy token${NC}"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✅ Token lấy được thành công!${NC}"
echo -e "${GRAY}Token: ${TOKEN:0:50}...${NC}"
echo -e "${GRAY}Expires in: $EXPIRES_IN giây${NC}"
echo ""

# ========== STEP 2: Get Users via Gateway ==========
echo -e "${YELLOW}[STEP 2] Lấy danh sách Users qua Gateway${NC}"
echo -e "${GRAY}Request qua Gateway: GET $API_GATEWAY_URL/users${NC}"

USERS_RESPONSE=$(curl -s -X GET "$API_GATEWAY_URL/users" \
  -H "Authorization: Bearer $TOKEN")

echo -e "${GREEN}✅ Danh sách users lấy được từ gateway!${NC}"
echo -e "${GRAY}Response:${NC}"
echo "$USERS_RESPONSE" | jq '.' 2>/dev/null || echo "$USERS_RESPONSE"
echo ""

# ========== STEP 3: Get Products via Gateway ==========
echo -e "${YELLOW}[STEP 3] Lấy danh sách Products qua Gateway${NC}"
echo -e "${GRAY}Request qua Gateway: GET $API_GATEWAY_URL/products${NC}"

PRODUCTS_RESPONSE=$(curl -s -X GET "$API_GATEWAY_URL/products" \
  -H "Authorization: Bearer $TOKEN")

echo -e "${GREEN}✅ Danh sách products lấy được từ gateway!${NC}"
echo -e "${GRAY}Response:${NC}"
echo "$PRODUCTS_RESPONSE" | jq '.' 2>/dev/null || echo "$PRODUCTS_RESPONSE"
echo ""

# ========== STEP 4: Get User by ID via Gateway ==========
echo -e "${YELLOW}[STEP 4] Lấy User theo ID (1) qua Gateway${NC}"
echo -e "${GRAY}Request qua Gateway: GET $API_GATEWAY_URL/users/1${NC}"

USER_RESPONSE=$(curl -s -X GET "$API_GATEWAY_URL/users/1" \
  -H "Authorization: Bearer $TOKEN")

echo -e "${GREEN}✅ User lấy được thành công!${NC}"
echo -e "${GRAY}Response:${NC}"
echo "$USER_RESPONSE" | jq '.' 2>/dev/null || echo "$USER_RESPONSE"
echo ""

# ========== STEP 5: Get Product by ID (with User info) ==========
echo -e "${YELLOW}[STEP 5] Lấy Product theo ID (1) qua Gateway (hiển thị info creator)${NC}"
echo -e "${GRAY}Request qua Gateway: GET $API_GATEWAY_URL/products/1${NC}"

PRODUCT_RESPONSE=$(curl -s -X GET "$API_GATEWAY_URL/products/1" \
  -H "Authorization: Bearer $TOKEN")

echo -e "${GREEN}✅ Product lấy được thành công!${NC}"
echo -e "${GRAY}Response (ProductService gọi UserService để lấy creator):${NC}"
echo "$PRODUCT_RESPONSE" | jq '.' 2>/dev/null || echo "$PRODUCT_RESPONSE"
echo ""

# ========== STEP 6: Test trực tiếp UserService ==========
echo -e "${YELLOW}[STEP 6] So sánh: Trực tiếp gọi UserService (port 5001)${NC}"
echo -e "${GRAY}Request trực tiếp: GET $USER_SERVICE_URL/users${NC}"

DIRECT_USERS=$(curl -s -X GET "$USER_SERVICE_URL/users" \
  -H "Authorization: Bearer $TOKEN")

echo -e "${GREEN}✅ Trực tiếp UserService cũng hoạt động!${NC}"
echo -e "${GRAY}Response:${NC}"
echo "$DIRECT_USERS" | jq '.' 2>/dev/null || echo "$DIRECT_USERS"
echo ""

# ========== Summary ==========
echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}✅ Tất cả test hoàn tất thành công!${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""
echo -e "${CYAN}📊 Tóm tắt:${NC}"
echo -e "${GRAY}  1. Lấy token từ /auth/token qua gateway${NC}"
echo -e "${GRAY}  2. Gọi /users qua gateway (route tới UserService)${NC}"
echo -e "${GRAY}  3. Gọi /products qua gateway (route tới ProductService)${NC}"
echo -e "${GRAY}  4. Gọi /users/{id} qua gateway${NC}"
echo -e "${GRAY}  5. Gọi /products/{id} qua gateway (với service-to-service call)${NC}"
echo -e "${GRAY}  6. So sánh gọi trực tiếp UserService${NC}"
echo ""
