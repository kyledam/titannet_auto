#!/bin/bash



echo "Chọn tùy chọn cài đặt:"
echo "1. Cài đặt cả Squid và Titan Node"
echo "2. Chỉ cài đặt Squid"
echo "3. Chỉ cài đặt Titan Node"
read -p "Nhập lựa chọn của bạn (1/2/3, mặc định là 1): " choice
choice=${choice:-1}

case $choice in
    1)

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


		#read -p "Nhập số core CPU (mặc định là 1 CORE): " cpu_core
		#cpu_core=${cpu_core:-1}

		#read -p "Nhập dung lượng RAM (mặc định là 2 GB): " memory_size
		#memory_size=${memory_size:-2}

		read -p "Nhập dung lượng lưu trữ (mặc định là 18 GB): " storage_size
		storage_size=${storage_size:-18}


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

		apt-get update
		apt-get install -y nano
		apt-get install -y squid
		wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/squid.conf
		rm /etc/squid/squid.conf
		cp squid.conf /etc/squid/squid.conf
		systemctl restart squid


		wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.18/titan_v0.1.18_linux_amd64.tar.gz

		tar -xf titan_v0.1.18_linux_amd64.tar.gz -C /usr/local

		mv /usr/local/titan_v0.1.18_linux_amd64 /usr/local/titan

		rm titan_v0.1.18_linux_amd64.tar.gz


		if [ ! -f ~/.bash_profile ]; then
			echo 'export PATH=$PATH:/usr/local/titan' >> ~/.bash_profile
			source ~/.bash_profile
		elif ! grep -q '/usr/local/titan' ~/.bash_profile; then
			echo 'export PATH=$PATH:/usr/local/titan' >> ~/.bash_profile
			source ~/.bash_profile
		fi

		# Chạy titan-edge daemon trong nền
		(titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0 &) &
		daemon_pid=$!

		echo "PID của titan-edge daemon: $daemon_pid"

		# Chờ 10 giây để đảm bảo rằng daemon đã khởi động thành công
		sleep 15

		# Chạy titan-edge bind trong nền
		(titan-edge bind --hash="$hash_value" https://api-test1.container1.titannet.io/api/v2/device/binding &) &
		bind_pid=$!

		echo "PID của titan-edge bind: $bind_pid"

		# Chờ cho quá trình bind kết thúc
		wait $bind_pid

		sleep 15

		# Tiến hành các cài đặt khác

		config_file="/root/.titanedge/config.toml"
		if [ -f "$config_file" ]; then
			sed -i "s/#StorageGB = 2/StorageGB = $storage_size/" "$config_file"
			echo "Đã thay đổi kích thước lưu trữ cơ sở dữ liệu thành $storage_size GB."
		   // sed -i "s/#MemoryGB = 1/MemoryGB = $memory_size/" "$config_file"
		   // echo "Đã thay đổi kích thước memory liệu thành $memory_size GB."
		   // sed -i "s/#Cores = 1/Cores = $cpu_core/" "$config_file"
		   // echo "Đã thay đổi core cpu liệu thành $cpu_core Core."
		else
			echo "Lỗi: Tệp cấu hình $config_file không tồn tại."
		fi

		echo "$service_content" | tee /etc/systemd/system/titand.service > /dev/null

		# Dừng các tiến trình liên quan đến titan-edge
		pkill titan-edge

		# Cập nhật systemd
		systemctl daemon-reload

		# Kích hoạt và khởi động titand.service
		systemctl enable titand.service
		systemctl start titand.service

		sleep 8
		ln -s /usr/local/titan/titan-edge /usr/local/bin
		# Hiển thị thông tin và cấu hình của titan-edge
		systemctl status titand.service && titan-edge config show && titan-edge info
		;;
	2)
        apt-get update
        apt-get install -y nano
        apt-get install -y squid
        wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/squid.conf
        rm /etc/squid/squid.conf
        cp squid.conf /etc/squid/squid.conf
        systemctl restart squid
        ;;
	3)
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


		#read -p "Nhập số core CPU (mặc định là 1 CORE): " cpu_core
		#cpu_core=${cpu_core:-1}

		#read -p "Nhập dung lượng RAM (mặc định là 2 GB): " memory_size
		#memory_size=${memory_size:-2}

		read -p "Nhập dung lượng lưu trữ (mặc định là 18 GB): " storage_size
		storage_size=${storage_size:-18}


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

		apt-get update
		apt-get install -y nano
		


		wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.18/titan_v0.1.18_linux_amd64.tar.gz

		tar -xf titan_v0.1.18_linux_amd64.tar.gz -C /usr/local

		mv /usr/local/titan_v0.1.18_linux_amd64 /usr/local/titan

		rm titan_v0.1.18_linux_amd64.tar.gz


		if [ ! -f ~/.bash_profile ]; then
			echo 'export PATH=$PATH:/usr/local/titan' >> ~/.bash_profile
			source ~/.bash_profile
		elif ! grep -q '/usr/local/titan' ~/.bash_profile; then
			echo 'export PATH=$PATH:/usr/local/titan' >> ~/.bash_profile
			source ~/.bash_profile
		fi

		# Chạy titan-edge daemon trong nền
		(titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0 &) &
		daemon_pid=$!

		echo "PID của titan-edge daemon: $daemon_pid"

		# Chờ 10 giây để đảm bảo rằng daemon đã khởi động thành công
		sleep 15

		# Chạy titan-edge bind trong nền
		(titan-edge bind --hash="$hash_value" https://api-test1.container1.titannet.io/api/v2/device/binding &) &
		bind_pid=$!

		echo "PID của titan-edge bind: $bind_pid"

		# Chờ cho quá trình bind kết thúc
		wait $bind_pid

		sleep 15

		# Tiến hành các cài đặt khác

		config_file="/root/.titanedge/config.toml"
		if [ -f "$config_file" ]; then
			sed -i "s/#StorageGB = 2/StorageGB = $storage_size/" "$config_file"
			echo "Đã thay đổi kích thước lưu trữ cơ sở dữ liệu thành $storage_size GB."
		   // sed -i "s/#MemoryGB = 1/MemoryGB = $memory_size/" "$config_file"
		   // echo "Đã thay đổi kích thước memory liệu thành $memory_size GB."
		   // sed -i "s/#Cores = 1/Cores = $cpu_core/" "$config_file"
		   // echo "Đã thay đổi core cpu liệu thành $cpu_core Core."
		else
			echo "Lỗi: Tệp cấu hình $config_file không tồn tại."
		fi

		echo "$service_content" | tee /etc/systemd/system/titand.service > /dev/null

		# Dừng các tiến trình liên quan đến titan-edge
		pkill titan-edge

		# Cập nhật systemd
		systemctl daemon-reload

		# Kích hoạt và khởi động titand.service
		systemctl enable titand.service
		systemctl start titand.service

		sleep 8
		ln -s /usr/local/titan/titan-edge /usr/local/bin
		# Hiển thị thông tin và cấu hình của titan-edge
		systemctl status titand.service && titan-edge config show && titan-edge info
		;;