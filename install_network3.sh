#!/bin/bash

# Download and extract the archive
wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/ubuntu-node-v1.0.tar
tar -xf ubuntu-node-v1.0.tar

# Change to the extracted directory
cd ubuntu-node || exit

# Run the manager.sh up command
bash manager.sh up


