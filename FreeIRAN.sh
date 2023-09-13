#!/bin/bash

# Introductory message
cat <<EOM

FreeIRAN:A simple bash script for setup Ubuntu Server
What does this script do? you can select to:

1. Update & Upgrade Server
2. Install essential packages
3. Install Speedtest
4. Create SWAP File
5. Enable BBR
6. Enable and configure Cron
7. Automatically update and restart the server every night at 01:00 GMT+3:30
8. Install X-UI
9. Install Pi-Hole Adblocker
10. Install & set WARP Proxy
11. Install Erlang MTProto Proxy
12. Install Hysteria II
13. Install TUIC v5

Manually set the parameters yourself when prompted during the setup.

EOM

# Ask the user if they want to proceed
read -p "Do you want to proceed with the setup? (y/n): " proceed

if [[ $proceed != "y" && $proceed != "Y" ]]; then
    echo "Setup aborted."
    exit 0
fi

# 1. Update & Upgrade Server
read -p "Do you want to update & upgrade the server? (y/n): " update_upgrade
if [[ $update_upgrade == "y" || $update_upgrade == "Y" ]]; then
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean && sudo apt clean
fi

# 2. Install essential packages
read -p "Do you want to install essential packages? (y/n): " install_packages
if [[ $install_packages == "y" || $install_packages == "Y" ]]; then
    sudo apt install -y curl nano certbot cron ufw htop dialog
fi

# 3. Install Speedtest
read -p "Do you want to install Speedtest? (y/n): " install_speedtest
if [[ $install_speedtest == "y" || $install_speedtest == "Y" ]]; then
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install -y speedtest-cli
fi

# 4. Create SWAP File
read -p "Do you want to create a SWAP file? (y/n): " create_swap
if [[ $create_swap == "y" || $create_swap == "Y" ]]; then
    read -p "Enter the SWAP file size (e.g., 1G for 1GB): " swap_size
    sudo fallocate -l $swap_size /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    sudo sysctl vm.swappiness=10
    sudo sysctl vm.vfs_cache_pressure=50
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
    echo "SWAP file of size $swap_size created and configured."
else
    echo "No SWAP file will be created."
fi

# 5. Enable BBR
read -p "Do you want to enable BBR? (y/n): " enable_bbr
if [[ $enable_bbr == "y" || $enable_bbr == "Y" ]]; then
    echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
fi

# 6. Enable and configure Cron
read -p "Do you want to set up automatic nightly updates and restarts? (y/n): " enable_cron
if [[ $enable_cron == "y" || $enable_cron == "Y" ]]; then
    sudo systemctl enable cron
    echo "Adding cron jobs..."
    echo "00 22 * * * /usr/bin/apt-get update && /usr/bin/apt-get upgrade -y && /usr/bin/apt-get autoremove -y && /usr/bin/apt-get autoclean -y && /usr/bin/apt-get clean -y" | sudo tee -a /etc/crontab
    echo "30 22 * * * /sbin/shutdown -r" | sudo tee -a /etc/crontab
fi

# 7. Install X-UI
read -p "Do you want to install X-UI? (y/n): " install_xui
if [[ $install_xui == "y" || $install_xui == "Y" ]]; then
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
fi

# 8. Install Pi-Hole Adblocker
read -p "Do you want to install Pi-Hole Adblocker? (y/n): " install_pihole
if [[ $install_pihole == "y" || $install_pihole == "Y" ]]; then
    curl -sSL https://install.pi-hole.net | bash
    pihole -a -p
    echo "nameserver 127.0.0.53" | sudo tee /etc/resolv.conf
fi

# 9. Install & set WARP Proxy
read -p "Do you want to install and set WARP Proxy? (y/n): " install_warp
if [[ $install_warp == "y" || $install_warp == "Y" ]]; then
    bash <(curl -fsSL git.io/warp.sh) proxy
fi

# 10. Install Erlang MTProto Proxy
read -p "Do you want to install Erlang MTProto Proxy? (y/n): " install_mtproto
if [[ $install_mtproto == "y" || $install_mtproto == "Y" ]]; then
    curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh
fi

# 11. Install Hysteria II
read -p "Do you want to install Hysteria II? (y/n): " install_hysteria
if [[ $install_hysteria == "y" || $install_hysteria == "Y" ]]; then
    bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/Hysteria-Installer/main/hysteria.sh)
fi

# 12. Install TUIC v5
read -p "Do you want to install TUIC v5? (y/n): " install_tuic
if [[ $install_tuic == "y" || $install_tuic == "Y" ]]; then
    bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/tuic-v5-installer/main/tuic-installer.sh)
fi

# Reminder message
cat <<EOM

Setup completed. Don't forget to:

1. Add your desired adlists via the Pi-hole web interface.
2. Update the Pi-hole database with [pihole -g].
3. Obtain SSL Certificates with [sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email yourmail@gmail.com -d sub.domain.com].
4. Change the SSH Port with [sudo nano /etc/ssh/sshd_config].
5. Set up UFW.
6. Change WARP License Key [warp-cli set-license <your-warp-plus-license-key>]
7. Change Server DNS to use Pi-hole [sudo nano /etc/resolv.conf]
8. Restart your server with [sudo shutdown -r now].

EOM

# Exit script
exit 0
