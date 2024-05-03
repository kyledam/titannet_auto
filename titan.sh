#!/bin/bash

# Download the titan release
echo "Downloading titan release..."
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.18/titan_v0.1.18_linux_amd64.tar.gz

# Extract the downloaded archive
echo "Extracting titan archive..."
sudo tar -xf titan_v0.1.18_linux_amd64.tar.gz -C /usr/local

# Move the extracted directory to /usr/local/titan
echo "Moving titan to /usr/local/titan..."
sudo mv /usr/local/titan_v0.1.18_linux_amd64 /usr/local/titan

# Start the titan-edge daemon
echo "Starting titan-edge daemon..."
cd /usr/local/titan
./titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0

# Prompt the user for the hash value
read -p "Enter the hash value: " hash

# Stop the titan-edge daemon
echo "Stopping titan-edge daemon..."
./titan-edge daemon stop

# Bind the titan-edge with the provided hash
echo "Binding titan-edge with the provided hash..."
./titan-edge bind --hash=$hash https://api-test1.container1.titannet.io/api/v2/device/binding

# Set the storage size for titan-edge
echo "Setting storage size for titan-edge..."
./titan-edge config set --storage-size 10GB

# Run the final command with nohup and redirect output to edge.log
echo "Running the final command with nohup..."
nohup ./titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0 > edge.log 2>&1 &

# Set up the script to run automatically on system boot
echo "Setting up the script to run automatically on system boot..."
cron_entry="@reboot $(pwd)/run_titan_commands.sh"
(crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

echo "Done!"