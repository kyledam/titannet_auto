#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and install dante-server
apt update -y
apt install dante-server -y

# Remove danted.conf if it exists
if [ -f /etc/danted.conf ]; then
    rm /etc/danted.conf
fi

# Prompt user for IP address
read -p "Enter your IP address: " ip_address

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
