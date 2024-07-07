#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and install dante-server and curl
apt update -y
apt install dante-server curl -y

# Remove danted.conf if it exists
if [ -f /etc/danted.conf ]; then
    rm /etc/danted.conf
fi

# Function to get and display IP addresses
get_ip_addresses() {
    echo "Available IP addresses:"
    ip -4 addr show | grep inet | awk '{print NR")", $2}' | cut -d'/' -f1
}

# Display IP addresses and let user choose
get_ip_addresses
echo "Enter the number of the IP address you want to use:"
read choice

# Get the selected IP address
ip_address=$(ip -4 addr show | grep inet | awk '{print $2}' | cut -d'/' -f1 | sed -n "${choice}p")

echo "You selected: $ip_address"

# Create new danted.conf file
cat > /etc/danted.conf << EOL
logoutput: stderr
internal: $ip_address port = 1080
external: $ip_address
socksmethod: username
user.privileged: root
user.unprivileged: nobody
user.libwrap: nobody
client pass {
    from: 0/0 to: 0/0
    log: error
}
socks pass {
    from: 0/0 to: 0/0
    log: error
}
EOL

# Create user 'kyledam' with password '123'
useradd -M -s /usr/sbin/nologin kyledam
echo "kyledam:123" | chpasswd

# Restart danted service
systemctl restart danted

echo "Configuration complete. Dante server has been restarted."
echo "User 'kyledam' has been created with password '123'."

# Wait for the service to fully start
sleep 3
rm setup_sock5.sh

# Test the SOCKS5 connection
echo "Testing SOCKS5 connection..."
curl_output=$(curl -x socks5://kyledam:123@$ip_address:1080 http://ifconfig.me)
curl_exit_code=$?

if [ $curl_exit_code -eq 0 ]; then
    echo "SOCKS5 connection test successful."
    echo "Your IP address according to ifconfig.me: $curl_output"
else
    echo "SOCKS5 connection test failed. Exit code: $curl_exit_code"
fi
