#!/bin/bash

# Script Restore Nextcloud - SIMPLE & COMPLETE
# Restore: App + Database + Data + HTTPS Certificate

set -e  # Exit on error

# ============================================
# CONFIGURATION
# ============================================
NETWORK_BACKUP="/media/restore"
EXPORT_DIR="$NETWORK_BACKUP/ox_exports"
DATA_BACKUP="$NETWORK_BACKUP/ox_data/data"
CERT_BACKUP="$NETWORK_BACKUP/ox_cert"
NEXTCLOUD_DATA="/var/snap/nextcloud/common/nextcloud/data"
LOG="/var/log/nextcloud-restore.log"

# ============================================
# COLORS
# ============================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# FUNCTIONS
# ============================================
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}" | tee -a "$LOG"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}" | tee -a "$LOG"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG"
    exit 1
}

# ============================================
# MAIN SCRIPT
# ============================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🚀 RESTORE NEXTCLOUD - COMPLETE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check root
[ "$EUID" -eq 0 ] || error "Cần chạy với sudo"

# ============================================
# PRE-CHECK
# ============================================
log "🔍 Kiểm tra điều kiện..."

# Check Nextcloud snap
snap list nextcloud >/dev/null 2>&1 || error "Nextcloud chưa cài: sudo snap install nextcloud"
log "✓ Nextcloud snap installed"

# Check services
if ! snap services nextcloud | grep -q "active"; then
    warn "Services chưa chạy đầy đủ, đang start..."
    snap start nextcloud
    sleep 30
fi
log "✓ Services running"

# Check network backup
[ -d "$NETWORK_BACKUP" ] || error "Network backup chưa mount: $NETWORK_BACKUP"
log "✓ Network backup accessible"

# Check data mount
if ! mountpoint -q "$NEXTCLOUD_DATA"; then
    warn "Data directory chưa mount vào ổ riêng"
    warn "Đang sử dụng storage mặc định"
fi
log "✓ Data directory ready"

# ============================================
# STEP 1: IMPORT APP & DATABASE
# ============================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  📥 BƯỚC 1: IMPORT APP & DATABASE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Find latest export
log "Tìm export backup..."
LATEST_ARCHIVE=$(find "$EXPORT_DIR" -name "????????-??????.tar.gz" -type f | sort -r | head -1)

[ -n "$LATEST_ARCHIVE" ] || error "Không tìm thấy file backup .tar.gz trong $EXPORT_DIR"

BACKUP_NAME=$(basename "$LATEST_ARCHIVE")
BACKUP_SIZE=$(du -sh "$LATEST_ARCHIVE" | cut -f1)
log "Tìm thấy: $BACKUP_NAME ($BACKUP_SIZE)"

# Extract
log "Đang extract..."
EXTRACT_DIR="/var/snap/nextcloud/current/nextcloud_import_$(date +%s)"
mkdir -p "$EXTRACT_DIR"

tar -xzf "$LATEST_ARCHIVE" -C "$EXTRACT_DIR" 2>&1 | tee -a "$LOG"
[ ${PIPESTATUS[0]} -eq 0 ] || error "Extract thất bại"

IMPORT_DIR=$(find "$EXTRACT_DIR" -maxdepth 1 -type d -name "????????-??????" | head -1)
[ -d "$IMPORT_DIR" ] || error "Không tìm thấy folder sau extract"

log "✓ Extract OK: $(basename $IMPORT_DIR)"

# Import (NO DATA - only app, config, database)
warn "Đang import app, config, database (KHÔNG import data)..."
warn "Quá trình này mất 5-15 phút. Vui lòng đợi..."

nextcloud.import -abc "$IMPORT_DIR" 2>&1 | tee -a "$LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "✓ Import thành công!"
else
    error "Import thất bại! Check log: $LOG"
fi

# Clean up
log "Dọn dẹp temp files..."
rm -rf "$EXTRACT_DIR"

# ============================================
# STEP 2: RSYNC DATA
# ============================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  💾 BƯỚC 2: RESTORE USER DATA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

[ -d "$DATA_BACKUP" ] || error "Data backup không tồn tại: $DATA_BACKUP"

DATA_SIZE=$(du -sh "$DATA_BACKUP" | cut -f1)
DATA_FILES=$(find "$DATA_BACKUP" -type f 2>/dev/null | wc -l)
log "Kích thước data: $DATA_SIZE"
log "Số lượng files: $DATA_FILES"

warn "Đang rsync data (MẤT NHIỀU THỜI GIAN - có thể vài giờ)..."

# Rsync with correct permissions
rsync -av --progress --chown=root:root --chmod=D0770,F0660 "$DATA_BACKUP/" "$NEXTCLOUD_DATA/" 2>&1 | tee -a "$LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "✓ Rsync data thành công!"
else
    error "Rsync thất bại!"
fi

# Verify permissions (backup check)
log "Verify permissions..."
chown -R root:root "$NEXTCLOUD_DATA" 2>/dev/null
chmod -R 0770 "$NEXTCLOUD_DATA" 2>/dev/null
log "✓ Permissions OK"

# ============================================
# STEP 3: SCAN & OPTIMIZE
# ============================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🔍 BƯỚC 3: SCAN & OPTIMIZE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Disable maintenance mode nếu còn
nextcloud.occ maintenance:mode --off 2>/dev/null

log "Scan files (mất 10-30 phút)..."
nextcloud.occ files:scan --all 2>&1 | tee -a "$LOG"

log "Optimize database..."
nextcloud.occ db:add-missing-indices 2>&1 | tee -a "$LOG"
nextcloud.occ db:add-missing-columns 2>&1 | tee -a "$LOG"

# ============================================
# STEP 4: ENABLE HTTPS
# ============================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🔐 BƯỚC 4: ENABLE HTTPS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ -d "$CERT_BACKUP" ]; then
    CERT_FILE="$CERT_BACKUP/cert.pem"
    KEY_FILE="$CERT_BACKUP/privkey.pem"
    CHAIN_FILE="$CERT_BACKUP/chain.pem"
    
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ] && [ -f "$CHAIN_FILE" ]; then
        log "Tìm thấy certificates trong $CERT_BACKUP"
        
        # Verify không rỗng
        if [ ! -s "$CERT_FILE" ] || [ ! -s "$KEY_FILE" ] || [ ! -s "$CHAIN_FILE" ]; then
            warn "Certificate files bị rỗng! Skip HTTPS"
        else
            # Copy vào snap certs directory
            SNAP_CERT_DIR="/var/snap/nextcloud/current/certs/custom"
            mkdir -p "$SNAP_CERT_DIR"
            
            log "Copy certificates..."
            cp "$CERT_FILE" "$SNAP_CERT_DIR/cert.pem"
            cp "$KEY_FILE" "$SNAP_CERT_DIR/privkey.pem"
            cp "$CHAIN_FILE" "$SNAP_CERT_DIR/chain.pem"
            
            chmod 600 "$SNAP_CERT_DIR"/*.pem
            chown root:root "$SNAP_CERT_DIR"/*.pem
            
            # Verify certificate valid
            if openssl x509 -in "$SNAP_CERT_DIR/cert.pem" -noout -text >/dev/null 2>&1; then
                log "✓ Certificate valid"
                
                # Enable HTTPS
                log "Enable HTTPS..."
                cd "$SNAP_CERT_DIR"
                nextcloud.enable-https custom -s cert.pem privkey.pem chain.pem 2>&1 | tee -a "$LOG"
                
                if [ ${PIPESTATUS[0]} -eq 0 ]; then
                    log "✓ HTTPS enabled thành công!"
                else
                    warn "Enable HTTPS có lỗi, check log"
                    warn "Thử manual: cd $SNAP_CERT_DIR && sudo nextcloud.enable-https custom -s cert.pem privkey.pem chain.pem"
                fi
            else
                warn "Certificate không hợp lệ! Skip HTTPS"
            fi
        fi
    else
        warn "Thiếu certificate files (cert.pem, privkey.pem, chain.pem)"
    fi
else
    warn "Không tìm thấy thư mục certificates: $CERT_BACKUP"
    log "Skip HTTPS - enable manual sau nếu cần"
fi

# ============================================
# SUMMARY
# ============================================
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ RESTORE HOÀN TẤT!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

log "Check status..."
nextcloud.occ status

echo -e "\n${BLUE}📊 THÔNG TIN:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Version: $(snap list nextcloud | grep nextcloud | awk '{print $2}')"
echo "💾 Data: $NEXTCLOUD_DATA"
echo "📊 Size: $(du -sh $NEXTCLOUD_DATA 2>/dev/null | cut -f1)"
echo "💿 Disk: $(df -h $NEXTCLOUD_DATA | tail -1 | awk '{print $5 " (" $3 "/" $2 ")"}')"
echo "📝 Log: $LOG"

echo -e "\n${BLUE}🌐 TRUY CẬP:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if nextcloud.occ config:system:get overwrite.cli.url >/dev/null 2>&1; then
    NC_URL=$(nextcloud.occ config:system:get overwrite.cli.url)
    echo "   $NC_URL"
else
    echo "   http://$(hostname -I | awk '{print $1}')"
    if [ -d "/var/snap/nextcloud/current/certs/custom" ]; then
        echo "   https://$(hostname -I | awk '{print $1}')"
    fi
fi

echo -e "\n${BLUE}📋 BƯỚC TIẾP THEO:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Truy cập web và đăng nhập"
echo "2. Kiểm tra files và users"
echo "3. Config domain nếu cần:"
echo "   sudo nextcloud.occ config:system:set trusted_domains 1 --value=your-domain.com"
echo "4. Config overwrite URL:"
echo "   sudo nextcloud.occ config:system:set overwrite.cli.url --value=https://your-domain.com"
echo ""

