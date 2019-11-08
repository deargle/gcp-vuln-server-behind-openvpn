#!/bin/bash
echo 'push "route 192.168.10.0 255.255.255.0"' | sudo tee -a /etc/openvpn/server.conf
sudo systemctl restart openvpn@server