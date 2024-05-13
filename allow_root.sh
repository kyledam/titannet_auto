#!/bin/bash

# Path to the sshd_config file
sshd_config="/etc/ssh/sshd_config"

# Line to add
new_line="PermitRootLogin yes"

# Check if the line already exists in the file
if ! grep -q "$new_line" "$sshd_config"; then
    # Add the line to the file
    echo "$new_line" >> "$sshd_config"
    echo "Added '$new_line' to $sshd_config"
else
    echo "'$new_line' already exists in $sshd_config"
fi

# Restart SSH and SSHD services
systemctl restart ssh sshd

echo "SSH and SSHD services restarted"