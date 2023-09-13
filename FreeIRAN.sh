#!/bin/bash

# Update & Upgrade Server
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean && sudo apt clean

# Install essential packages
sudo apt install -y curl nano certbot cron ufw htop dialog

# Clean journal logs
sudo journalctl --vacuum-size=50M

# Install Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install -y speedtest-cli

# Create SWAP File
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Set sysctl parameters
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf

# Change TimeZone
sudo dpkg-reconfigure tzdata

# Enable and configure Cron
sudo systemctl enable cron
crontab -e

# Install X-UI
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)

# Install Pi-Hole
curl -sSL https://install.pi-hole.net | bash
pihole -a -p

# Change Local DNS to PiHole
echo "nameserver 127.0.0.53" | sudo tee /etc/resolv.conf

# Change Lighttpd Conf
sudo nano /etc/lighttpd/lighttpd.conf
sudo service lighttpd restart

# Install WARP WireProxy
wget -N https://raw.githubusercontent.com/fscarmen/warp/main/menu.sh && bash menu.sh

# Install Erlang MTProto Proxy
curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh

# Install Hysteria II
bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/Hysteria-Installer/main/hysteria.sh)

# Install TUIC v5
bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/tuic-v5-installer/main/tuic-installer.sh)

# Reminder message
cat <<EOM

Setup completed. Don't forget to:

1. Add your desired adlists via Pi-hole web interface
2. Update Pi-hole Database with [pihole -g]
3. You can connect/disconnect WireProxy with [warp y]
5. Obtain SSL Certificates with [sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email mymail@gmail.com -d sub.domain.com]
6. Change SSH Port with [sudo nano /etc/ssh/sshd_config]
7. Setup UFW
8. Restart your server with [sudo shutdown -r now]

EOM

# Exit script
exit 0
