#!/bin/bash
wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v1.0.tar
tar -xf ubuntu-node-v1.0.tar 
cd ubuntu-node
bash manager.sh up 

service_content="
[Unit]
Description=Titan Node
After=network.target
StartLimitIntervalSec=0

[Service]
User=root
ExecStart=bash /root/ubuntu-node/manager.sh up
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
"

echo "$service_content" | tee /etc/systemd/system/network3d.service > /dev/null
pkill node
systemctl daemon-reload

# Kích hoạt và khởi động network3d.service
systemctl enable network3d.service
systemctl start network3d.service