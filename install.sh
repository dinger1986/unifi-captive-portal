#!/bin/bash

# Get Username
uname=$(whoami)

#Set ip address for UCP
echo -ne "Enter your UCP IP Address${NC}: "
read ipaddr

#Set username for UCP
echo -ne "Enter your UCP Username${NC}: "
read user

#Set password for UCP
echo -ne "Enter your UCP Password${NC}: "
read password

#Set Site for UCP
echo -ne "Enter your UCP Site (if you only have one its most likely default)${NC}: "
read site

#Set Name for Portal
echo -ne "Enter your preferred name for the UCP Portal${NC}: "
read ucpname

#Set redirect URL
echo -ne "Enter your preferred URL for users to go to once connected${NC}: "
read redirurl

# Make Folder /opt/
if [ ! -d "/opt/" ]; then
    echo "Creating /opt/"
    sudo mkdir -p /opt/
fi
cd /opt/

#Download latest version of Unifi Captive Portal
sudo apt update
sudo apt install git -y
git clone https://github.com/dinger1986/unifi-captive-portal.git
sudo chown "${uname}" -R /opt/unifi-captive-portal

#Download and install latest version of Golang
sudo apt install wget software-properties-common apt-transport-https -y
wget https://go.dev/dl/go1.18.3.linux-amd64.tar.gz
sudo tar -zxvf go1.18.3.linux-amd64.tar.gz -C /usr/local/
echo "export PATH=/usr/local/go/bin:${PATH}" | sudo tee /etc/profile.d/go.sh
source /etc/profile.d/go.sh
rm -rf go1.18.3.linux-amd64.tar.gz

#Compile UCP
cd unifi-captive-portal/
go mod init ucp
go get gopkg.in/yaml.v2 
go get github.com/sirupsen/logrus
env GOOS=linux GOARCH=amd64 go build -o ucp-server main.go

config="$(cat << EOF
unifi_url: 'https://${ipaddr}:8443'
unifi_username: '${user}'
unifi_password: '${password}'
unifi_site: '${site}'
title: '${ucpname}'
intro: >
  To join our guest network, please agree to the Terms of Service below.
tos: |
  By accepting this agreement and accessing the wireless network, you acknowledge that you are of legal age, you have read and understood, and agree to be bound by this agreement.

  (*) The wireless network service is provided by the property owners and is completely at their discretion. Your access to the network may be blocked, suspended, or terminated at any time for any reason.
  (*) You agree not to use the wireless network for any purpose that is unlawful or otherwise prohibited and you are fully responsible for your use.
  (*) The wireless network is provided "as is" without warranties of any kind, either expressed or implied. 
minutes: 600
redirect_url: '${redirurl}'
EOF
)"
echo "${config}" | sudo tee /opt/unifi-captive-portal/unifi-portal.yml > /dev/null

# Make Folder /var/log/ucp/
if [ ! -d "/var/log/ucp" ]; then
    echo "Creating /var/log/ucp"
    sudo mkdir -p /var/log/ucp/
fi
sudo chown "${uname}" -R /var/log/ucp/

# Setup Systemd to launch ucp
ucpconf="$(cat << EOF
[Unit]
Description=Unifi Captive Portal Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/opt/unifi-captive-portal/ucp-server
WorkingDirectory=/opt/unifi-captive-portal/
User=${uname}
Group=${uname}
Restart=always
StandardOutput=append:/var/log/ucp/server.log
StandardError=append:/var/log/ucp/server.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${ucpconf}" | sudo tee /etc/systemd/system/ucp.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable ucp.service
sudo systemctl start ucp.service

#Install nginx
sudo apt install -y nginx

nginx="$(cat << EOF
server {
    listen 80;
    listen [::]:80;
    access_log /var/log/ucp/webaccess.log;
    error_log /var/log/ucp/weberror.log;
    location / {
        proxy_pass http://localhost:4646;
    }

}
EOF
)"
echo "${nginx}" | sudo tee /etc/nginx/sites-available/ucp.conf > /dev/null

sudo ln -s /etc/nginx/sites-available/ucp.conf /etc/nginx/sites-enabled/ucp.conf

sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

sudo systemctl restart nginx

echo -e "Unifi Captive Portal is now installed."
