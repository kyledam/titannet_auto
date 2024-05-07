#!/bin/bash

# Download and extract the archive
wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v1.0.tar
tar -xf ubuntu-node-v1.0.tar

# Change to the extracted directory
cd ubuntu-node || exit

# Run the manager.sh up command
bash manager.sh up

# Create the service file content
service_content=$(cat <<-END
[Unit]
Description=Titan Node Manager
After=network.target

[Service]
ExecStart=/bin/bash /root/ubuntu-node/manager.sh up
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
END
)

# Create the service file
echo "$service_content" | sudo tee /etc/systemd/system/network3.service > /dev/null

# Reload systemd daemon and start the service
sudo systemctl daemon-reload
sudo systemctl enable network3.service
sudo systemctl start network3.service
