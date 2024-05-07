#!/bin/bash

echo "--------------------------- Cấu hình máy chủ ---------------------------"

echo "Số lõi CPU: " $(nproc --all) "CORE"

echo -n "Dung lượng RAM: " && free -h | awk '/Mem/ {sub(/Gi/, " GB", $2); print $2}'

echo "Dung lượng ổ cứng:" $(df -B 1G --total | awk '/total/ {print $2}' | tail -n 1) "GB"

echo "------------------------------------------------------------------------"

echo "--------------------------- BASH SHELL TITAN ---------------------------"

# Lấy giá trị hash từ terminal

echo "Nhap ma Hash cua ban (Identity code): "

read hash_value

# Kiểm tra nếu hash_value là chuỗi rỗng (người dùng chỉ nhấn Enter) thì dừng chương trình

if [ -z "$hash_value" ]; then
    echo "Không có giá trị hash được nhập. Dừng chương trình."
    exit 1
fi

echo "Nhập số core CPU (mặc định là 1 CORE): " cpu_core
cpu_core=${cpu_core:-1}

read -p "Nhập dung lượng RAM (mặc định là 2 GB): " memory_size
memory_size=${memory_size:-2}

read -p "Nhập dung lượng lưu trữ (mặc định là 18 GB): " storage_size
storage_size=${storage_size:-18}

# Prompt user if they want to use a different storage path
read -p "Bạn có muốn sử dụng đường dẫn lưu trữ khác không? (y/n, mặc định là n): " use_custom_path
use_custom_path=${use_custom_path:-n}

# If user wants to use a custom path, prompt for the path
if [ "$use_custom_path" == "y" ] || [ "$use_custom_path" == "Y" ]; then
    read -p "Nhập đường dẫn lưu trữ mới (mặc định là /media/titan): " storage_path
    storage_path=${storage_path:-/media/titan}
else
    storage_path="/media/titan"
fi

service_content="

[Unit]
Description=Titan Node
After=network.target
StartLimitIntervalSec=0

[Service]
User=root
ExecStart=/usr/local/titan/titan-edge daemon start
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target

"

# ... (remaining script code) ...

# Check if the user wants to use a custom storage path
if [ "$use_custom_path" == "y" ] || [ "$use_custom_path" == "Y" ]; then
    echo "Dừng dịch vụ titand..."
    systemctl stop titand

    echo "Đặt đường dẫn lưu trữ mới..."
    titan-edge config set --storage-path "$storage_path"

    echo "Đặt kích thước lưu trữ mới ($storage_size GB)..."
    titan-edge config set --storage-size "${storage_size}GB"

    echo "Khởi động lại dịch vụ titand..."
    systemctl start titand
fi

# Hiển thị thông tin và cấu hình của titan-edge
systemctl status titand.service && titan-edge config show && titan-edge info