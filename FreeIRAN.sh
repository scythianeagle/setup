#!/bin/bash

# Introductory message
cat <<EOM
What this script does:

1. Update & Upgrade Server
2. Install essential packages
3. Install Speedtest
4. Create SWAP File
5. Enable BBR
6. Enable and configure Cron
7. Automatically update and restart the server every night at 01:00 GMT+3:30
8. Install X-UI
9. Install Pi-Hole Adblocker
10. Change Local DNS to PiHole
11. Install WARP WireProxy
12. Install Erlang MTProto Proxy
13. Install Hysteria II
14. Install TUIC v5

Manually set the parameters yourself when prompted during the setup.

EOM

# Ask the user if they want to proceed
read -p "Do you want to proceed with the setup? (yes/no): " proceed

if [[ $proceed != "yes" && $proceed != "YES" ]]; then
    echo "Setup aborted."
    exit 0
fi

# Update & Upgrade Server
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean && sudo apt clean

# Install essential packages
sudo apt install -y curl nano certbot cron ufw htop dialog

# Clean journal logs
sudo journalctl --vacuum-size=50M

# Install Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install -y speedtest-cli

# Ask the user if they want to create a SWAP file
read -p "Do you want to create a SWAP file? (yes/no): " create_swap

if [[ $create_swap == "yes" || $create_swap == "YES" ]]; then
    # Ask for the SWAP file size
    read -p "Enter the SWAP file size (e.g., 1G for 1GB): " swap_size

    # Create the SWAP file with the specified size
    sudo fallocate -l $swap_size /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    # Set sysctl parameters
    sudo sysctl vm.swappiness=10
    sudo sysctl vm.vfs_cache_pressure=50
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

    echo "SWAP file of size $swap_size created and configured."
else
    echo "No SWAP file will be created."
fi

# Set TCP congestion control settings
echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf

# Enable and configure Cron
sudo systemctl enable cron

# Add cron jobs to update and upgrade the system daily at 00:30 GMT+3:30
echo "00 22 * * * /usr/bin/apt-get update && /usr/bin/apt-get upgrade -y && /usr/bin/apt-get autoremove -y && /usr/bin/apt-get autoclean -y && /usr/bin/apt-get clean -y" | sudo tee -a /etc/crontab

# Add a cron job to reboot the server daily at 01:00 GMT+3:30
echo "30 22 * * * /sbin/shutdown -r" | sudo tee -a /etc/crontab

# Install X-UI
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)

# Install Pi-Hole
curl -sSL https://install.pi-hole.net | bash
pihole -a -p

# Change Lighttpd Conf
sudo nano /etc/lighttpd/lighttpd.conf
sudo service lighttpd restart

# Install WARP Proxy
bash <(curl -fsSL git.io/warp.sh) proxy

# Install Erlang MTProto Proxy
curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh

# Install Hysteria II
bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/Hysteria-Installer/main/hysteria.sh)

# Install TUIC v5
bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/tuic-v5-installer/main/tuic-installer.sh)

# Change Local DNS to Pi-Hole
echo "nameserver 127.0.0.53" | sudo tee /etc/resolv.conf

# Reminder message
cat <<EOM

Setup completed. Don't forget to:

1. Add your desired adlists via the Pi-hole web interface.
2. Update the Pi-hole database with [pihole -g].
3. Connect/disconnect WireProxy with [warp y].
4. Obtain SSL Certificates with [sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email mymail@gmail.com -d sub.domain.com].
5. Change the SSH Port with [sudo nano /etc/ssh/sshd_config].
6. Set up UFW.
7. Restart your server with [sudo shutdown -r now].

EOM

# Exit script
exit 0
