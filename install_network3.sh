#!/bin/bash

echo "Select an option:"
echo "1. Install"
echo "2. Update"
read -p "Enter option number: " option

case $option in
    1)
        # Download and extract the archive
        cd ~
        wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v1.0.tar
        tar -xf ubuntu-node-v1.0.tar

        # Change to the extracted directory
        cd ubuntu-node || exit

        # Run the manager.sh up command
        bash manager.sh up
        ;;
    2)
        # Stop the code in /ubuntu-node
        cd ~
        cd ubuntu-node || exit
        bash manager.sh down

        # Delete all files in /ubuntu-node
        rm -rf /root/ubuntu-node/*

        # Download the new archive
        cd ~
        wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v1.1.tar
        tar -xf ubuntu-node-v1.1.tar

        # Change to the extracted directory
        cd ubuntu-node || exit

        # Run the manager.sh up command
        bash manager.sh up
        ;;
    *)
        echo "Invalid option"
        ;;
esac
