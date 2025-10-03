#!/bin/bash

# Script to set up ONLYOFFICE directories, copy certificates, and run Docker container
set -e  # Exit on error

# ============================================
# CONFIGURATION
# ============================================
CERT_BACKUP="/media/restore/ox_cert"
ONLYOFFICE_BASE_DIR="/app/onlyoffice/DocumentServer"
LOG="/var/log/onlyoffice-setup.log"

# ============================================
# COLORS
# ============================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================
# FUNCTIONS
# ============================================
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}" | tee -a "$LOG"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️ $1${NC}" | tee -a "$LOG"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG"
    exit 1
}

# ============================================
# MAIN SCRIPT
# ============================================
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} 🚀 SETUP ONLYOFFICE DOCUMENT SERVER${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check root
[ "$EUID" -eq 0 ] || error "Cần chạy với sudo"

# Check Docker
command -v docker >/dev/null 2>&1 || error "Docker chưa cài đặt. Cài đặt Docker trước: sudo apt install docker.io"

# Step 1: Create directories
log "Tạo các thư mục cần thiết..."
mkdir -p "$ONLYOFFICE_BASE_DIR/logs" \
         "$ONLYOFFICE_BASE_DIR/data/certs" \
         "$ONLYOFFICE_BASE_DIR/lib" \
         "$ONLYOFFICE_BASE_DIR/db"
log "✓ Tạo thư mục thành công: $ONLYOFFICE_BASE_DIR/{logs,data/certs,lib,db}"

# Step 2: Copy certificates
log "Kiểm tra certificate files..."
for file in "$CERT_BACKUP/onlyoffice.crt" "$CERT_BACKUP/onlyoffice.key"; do
    [ -f "$file" ] || error "Không tìm thấy $file trong $CERT_BACKUP"
    [ -s "$file" ] || error "File $file rỗng"
done

log "Copy certificates sang $ONLYOFFICE_BASE_DIR/data/certs..."
cp "$CERT_BACKUP/onlyoffice.crt" "$ONLYOFFICE_BASE_DIR/data/certs/"
cp "$CERT_BACKUP/onlyoffice.key" "$ONLYOFFICE_BASE_DIR/data/certs/"
chown -R root:root "$ONLYOFFICE_BASE_DIR/data/certs"
chmod 600 "$ONLYOFFICE_BASE_DIR/data/certs/onlyoffice.crt"
chmod 600 "$ONLYOFFICE_BASE_DIR/data/certs/onlyoffice.key"
log "✓ Copy certificates thành công"

# Step 3: Verify certificates
log "Kiểm tra certificate validity..."
if ! openssl x509 -in "$ONLYOFFICE_BASE_DIR/data/certs/onlyoffice.crt" -noout -text >/dev/null 2>&1; then
    warn "Certificate không hợp lệ! Vẫn tiếp tục nhưng HTTPS có thể gặp vấn đề."
fi
if ! openssl rsa -in "$ONLYOFFICE_BASE_DIR/data/certs/onlyoffice.key" -check >/dev/null 2>&1; then
    warn "Private key không hợp lệ! Vẫn tiếp tục nhưng HTTPS có thể gặp vấn đề."
fi
log "✓ Kiểm tra certificates hoàn tất"

# Step 4: Run ONLYOFFICE Docker container
log "Khởi chạy ONLYOFFICE Docker container..."
docker run -i -t -d -p 8081:80 -p 4443:443 --restart=always \
    -e USE_UNAUTHORIZED_STORAGE=true \
    -e JWT_SECRET=9V9biIrMuh15YUAgNHAU \
    -v "$ONLYOFFICE_BASE_DIR/logs:/var/log/onlyoffice" \
    -v "$ONLYOFFICE_BASE_DIR/data:/var/www/onlyoffice/Data" \
    -v "$ONLYOFFICE_BASE_DIR/lib:/var/lib/onlyoffice" \
    -v "$ONLYOFFICE_BASE_DIR/db:/var/lib/postgresql" \
    onlyoffice/documentserver 2>&1 | tee -a "$LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "✓ Docker container khởi chạy thành công"
else
    error "Khởi chạy Docker container thất bại! Check log: $LOG"
fi

# Step 5: Verify container
CONTAINER_ID=$(docker ps -q -f "ancestor=onlyoffice/documentserver")
if [ -n "$CONTAINER_ID" ]; then
    log "Container ID: $CONTAINER_ID"
    log "Kiểm tra trạng thái container..."
    docker ps -f "id=$CONTAINER_ID"
else
    error "Không tìm thấy container đang chạy!"
fi

# Step 6: Instructions for Nextcloud integration
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} ✅ SETUP HOÀN TẤT!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
log "Hướng dẫn tích hợp với Nextcloud:"
echo "1. Cài đặt ONLYOFFICE app trong Nextcloud:"
echo "   sudo nextcloud.occ app:install onlyoffice"
echo "   sudo nextcloud.occ app:enable onlyoffice"
echo "2. Cấu hình ONLYOFFICE:"
echo "   sudo nextcloud.occ config:app:set onlyoffice DocumentServerUrl --value='https://<server-ip>:4443'"
echo "   sudo nextcloud.occ config:app:set onlyoffice jwt_secret --value='9V9biIrMuh15YUAgNHAU'"
echo "3. Kiểm tra truy cập:"
echo "   - HTTP: http://<server-ip>:8081"
echo "   - HTTPS: https://<server-ip>:4443"
echo "4. Log file: $LOG"
echo -e "\n${GREEN}✓ Script hoàn thành!${NC}"
