#!/bin/bash
cd ~
rm -f /etc/systemd/system/container-getty@.service.d/override.conf
mkdir /etc/systemd/system/container-getty@.service.d
wget https://raw.githubusercontent.com/kyledam/titannet_auto/main/override.conf
cp override.conf /etc/systemd/system/container-getty@.service.d/override.conf
rm -f autologin.sh
