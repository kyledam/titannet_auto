#!/bin/bash
cd ~
rm -f /root/install_network3.sh
echo "Select an option:"
echo "1. Install"
echo "2. Update"
read -p "Enter option number: " option

case $option in
    1)
        # Download and extract the archive
        cd ~
        apt update -y
        apt upgrade -y
        apt install net-tools -y
        wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v2.1.1.tar.gz
        tar -xvzf ubuntu-node-v2.1.1.tar.gz
        rm -f ubuntu-node-v2.1.1.tar.gz
        # Change to the extracted directory
        cd ubuntu-node || exit

        # Run the manager.sh up command
        bash manager.sh up
        rm -f /root/install_network3.sh
        ;;
    2)
        # Stop the code in /ubuntu-node
        cd ~
        apt update -y
        apt install net-tools -y
        cd ubuntu-node || exit
        bash manager.sh down
        wait
        # Wait for 2 seconds
        sleep 5

        # Delete all files in /ubuntu-node
        rm -rf /root/ubuntu-node/*

        # Download the new archive
        cd ~
        wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v2.1.1.tar.gz
        tar -xvzf ubuntu-node-v2.1.1.tar.gz
        rm -f ubuntu-node-v2.1.1.tar.gz
        # Change to the extracted directory
        cd ubuntu-node || exit
        # Wait for 2 seconds
        sleep 4
        # Run the manager.sh up command
        bash manager.sh up
        rm -f /root/install_network3.sh
        ;;
    *)
        echo "Invalid option"
        ;;
esac
