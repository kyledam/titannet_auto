#!/bin/bash

# Define the URL of the tar file
TAR_URL="https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v1.0.tar"
TAR_FILE="ubuntu-node-v1.0.tar"
EXTRACTED_DIR="ubuntu-node"
SERVICE_NAME="ubuntu-node.service"

# Download the tar file
echo "Downloading tar file from $TAR_URL..."
wget $TAR_URL -O $TAR_FILE
if [ $? -ne 0 ]; then
  echo "Failed to download $TAR_FILE"
  exit 1
fi

# Extract the tar file
echo "Extracting $TAR_FILE..."
tar -xf $TAR_FILE
if [ $? -ne 0 ]; then
  echo "Failed to extract $TAR_FILE"
  exit 1
fi

# Change to the extracted directory
echo "Changing to directory $EXTRACTED_DIR..."
cd $EXTRACTED_DIR || { echo "Directory $EXTRACTED_DIR not found"; exit 1; }

# Create a systemd service file
echo "Creating systemd service file..."
cat <<EOL | sudo tee /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=Run manager.sh up for ubuntu-node
After=network.target

[Service]
Type=simple
WorkingDirectory=$(pwd)
ExecStart=/bin/bash manager.sh up
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling $SERVICE_NAME to start on boot..."
sudo systemctl enable $SERVICE_NAME

# Start the service now
echo "Starting $SERVICE_NAME..."
sudo systemctl start $SERVICE_NAME

echo "Service $SERVICE_NAME created and started successfully."
