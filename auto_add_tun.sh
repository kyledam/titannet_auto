#!/bin/bash

# Function to prompt user for input
get_input() {
    read -p "Please select file(s) to modify (e.g., 125 or 125-129): " input
}

# Function to check if lines exist in a file
lines_exist() {
    file="$1"
    line1="lxc.cgroup.devices.allow: c 10:200 rwm"
    line2="lxc.cgroup2.devices.allow: c 10:200 rwm"
    line3="lxc.mount.entry: /dev/net dev/net none bind,create=dir"
    if grep -Fxq "$line1" "$file" && grep -Fxq "$line2" "$file" && grep -Fxq "$line3" "$file"; then
        return 0  # Lines exist
    else
        return 1  # Lines do not exist
    fi
}

# Function to process a single file
process_file() {
    file="/etc/pve/lxc/$1.conf"
    if [ -f "$file" ]; then
        if ! lines_exist "$file"; then
            echo "lxc.cgroup.devices.allow: c 10:200 rwm" >> "$file"
            echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> "$file"
            echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir" >> "$file"
            echo "Modified $file"
        else
            echo "Lines already exist in $file, skipping..."
        fi
    else
        echo "$file does not exist"
    fi
}

# Function to process a range of files
process_range() {
    range=$(echo "$1" | sed 's/-/ /')
    start=$(echo "$range" | cut -d' ' -f1)
    end=$(echo "$range" | cut -d' ' -f2)
    for ((i=$start; i<=$end; i++)); do
        process_file "$i"
    done
}

# Main logic
get_input
if [[ "$input" =~ ^[0-9]+$ ]]; then
    process_file "$input"
elif [[ "$input" =~ ^[0-9]+-[0-9]+$ ]]; then
    process_range "$input"
else
    echo "Invalid input"
fi