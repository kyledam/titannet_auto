#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to validate port number
validate_port() {
    if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# Get user inputs
read -p "Enter port number for Squid proxy (1-65535): " PORT
while ! validate_port "$PORT"; do
    echo "Invalid port number. Please enter a number between 1 and 65535."
    read -p "Enter port number for Squid proxy (1-65535): " PORT
done

read -p "Enter username for Squid authentication: " USERNAME
while [[ -z "$USERNAME" ]]; do
    echo "Username cannot be empty."
    read -p "Enter username for Squid authentication: " USERNAME
done

# Install required packages
echo "Installing Squid and Apache utilities..."
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y squid apache2-utils
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y squid httpd-tools
else
    echo "Unsupported package manager. Please install Squid manually."
    exit 1
fi

# Backup original config if exists
if [ -f /etc/squid/squid.conf ]; then
    cp /etc/squid/squid.conf /etc/squid/squid.conf.backup
fi

# Create passwords file and get password with confirmation
mkdir -p /etc/squid
echo "Please enter password for user $USERNAME (you will need to type it twice):"
htpasswd -c /etc/squid/passwords "$USERNAME"

# Create new Squid configuration
cat > /etc/squid/squid.conf << EOL
acl localnet src 0.0.0.1-0.255.255.255	# RFC 1122 "this" network (LAN)
acl sms src 202.78.228.64/26
acl localnet src 10.0.0.0/8		# RFC 1918 local private network (LAN)
acl localnet src 100.64.0.0/10		# RFC 6598 shared address space (CGN)
acl localnet src 169.254.0.0/16 	# RFC 3927 link-local (directly plugged) machines
acl localnet src 172.16.0.0/12		# RFC 1918 local private network (LAN)
acl localnet src 192.168.0.0/16		# RFC 1918 local private network (LAN)
acl localnet src fc00::/7       	# RFC 4193 local private network range
acl localnet src fe80::/10      	# RFC 4291 link-local (directly plugged) machines
acl local_network src 192.168.100.0/24
acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http
#http_access allow local_network
http_access deny !Safe_ports
#http_access allow localhost manager
http_access deny manager
#http_access allow localhost
#http_access allow localnet
#http_access allow sms
http_access deny to_localhost
include /etc/squid/conf.d/*.conf
http_port $PORT
coredump_dir /var/spool/squid
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern \/(Packages|Sources)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
refresh_pattern \/Release(|\.gpg)$ 0 0% 0 refresh-ims
refresh_pattern \/InRelease$ 0 0% 0 refresh-ims
refresh_pattern \/(Translation-.*)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
refresh_pattern .		0	20%	4320
header_access Allow allow all
header_access Authorization allow all
header_access Cache-Control allow all
header_access Content-Encoding allow all
header_access Content-Length allow all
header_access Content-Type allow all
header_access Date allow all
header_access Expires allow all
header_access Host allow all
header_access If-Modified-Since allow all
header_access Last-Modified allow all
header_access Location allow all
header_access Pragma allow all
header_access Accept allow all
header_access Accept-Enncoding allow all
header_access Accept-Language allow all
header_access Content-Language allow all
header_access Mime-Version allow all
header_access Cookie allow all
header_access Set_Cookie allow all
header_access Retry-After allow all
header_access Title allow all
header_access Connection allow all
header_access Proxy-Connection allow all
header_access All deny all
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
dns_v4_first on
via off
forwarded_for delete
EOL

# Create squid conf.d directory if it doesn't exist
mkdir -p /etc/squid/conf.d

# Set proper permissions
chown -R proxy:proxy /etc/squid
chmod 755 /etc/squid
chmod 644 /etc/squid/squid.conf

# Restart Squid service
echo "Restarting Squid service..."
if command -v systemctl &> /dev/null; then
    systemctl restart squid
else
    service squid restart
fi

# Check if Squid is running
if pgrep -x "squid" >/dev/null; then
    echo "Squid installation completed successfully!"
    echo "Proxy is running on port: $PORT"
    echo "Username: $USERNAME"
    echo "Please save these credentials"
else
    echo "Error: Squid failed to start. Please check the logs at /var/log/squid/error.log"
fi
