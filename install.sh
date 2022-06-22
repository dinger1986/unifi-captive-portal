#!/bin/bash

# Get Username
uname=$(whoami)

# Make Folder /opt/
if [ ! -d "/opt/" ]; then
    echo "Creating /opt/"
    sudo mkdir -p /opt/
fi
cd /opt/

#Download latest version of Rustdesk
git clone https://github.com/dinger1986/unifi-captive-portal.git
sudo chown "${uname}" -R /opt/unifi-captive-portal
env GOOS=linux GOARCH=amd64 go build -o ucp-server main.go

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
WorkingDirectory=/opt/ucp/
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

#Get WAN IP
wanip=$(dig @resolver4.opendns.com myip.opendns.com +short)

pubname=$(find /opt/rustdesk -name *.pub)
key=$(cat "${pubname}")

sudo rm "${TMPFILE}"


echo -e "Your IP is ${wanip}"
echo -e "Install Rustdesk on your machines and change your public key and IP/DNS name to the above"
