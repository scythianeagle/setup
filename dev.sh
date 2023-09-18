#!/bin/bash

# FreeIRAN v.2.1.0 Beta
# Brave hearts unite for a Free Iran, lighting the path to a brighter future with unwavering determination.
# ErfanNamira
# https://github.com/ErfanNamira/FreeIRAN

# Check for sudo privileges
if [[ $EUID -ne 0 ]]; then
  if [[ $(sudo -n true 2>/dev/null) ]]; then
    echo "This script will be run with sudo privileges."
  else
    echo "This script must be run with sudo privileges."
    exit 1
  fi
fi

# 1. Function to perform system updates and cleanup
system_update() {
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt autoremove -y
  sudo apt autoclean -y
  sudo apt clean -y

  dialog --msgbox "System updates and cleanup completed." 10 60
}

# 2. Function to install essential packages
install_essential_packages() {
  packages=("curl" "nano" "certbot" "cron" "ufw" "htop" "net-tools")

  package_installed() {
    dpkg -l | grep -q "^ii  $1"
  }

  for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
      sudo apt install -y "$pkg"
    fi
  done
}

# 3. Function to install Speedtest
install_speedtest() {
  dialog --title "Install Speedtest" --yesno "Do you want to install Speedtest?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get -y install speedtest
    dialog --msgbox "Speedtest has been installed successfully. You can now run it by entering 'speedtest' in the terminal." 10 40
  else
    dialog --msgbox "Skipping installation of Speedtest." 10 40
  fi
}

# 4. Function to create a swap file
create_swap_file() {
  if [ -f /swapfile ]; then
    dialog --title "Swap File" --msgbox "A swap file already exists. Skipping swap file creation." 10 60
  else
    dialog --title "Swap File" --inputbox "Enter the size of the swap file (e.g., 2G for 2 gigabytes):" 10 60 2> swap_size.txt
    swap_size=$(cat swap_size.txt)

    if [[ "$swap_size" =~ ^[0-9]+[GgMm]$ ]]; then
      sudo fallocate -l "$swap_size" /swapfile
      sudo chmod 600 /swapfile
      sudo mkswap /swapfile
      sudo swapon /swapfile
	    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
      sudo sysctl vm.swappiness=10
      sudo sysctl vm.vfs_cache_pressure=50
	    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
      echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
      dialog --msgbox "Swap file created successfully with a size of $swap_size." 10 60
    else
      dialog --msgbox "Invalid swap file size. Please provide a valid size (e.g., 2G for 2 gigabytes)." 10 60
    fi
  fi
}

# 5. Function to enable BBR
enable_bbr() {
  echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf

  dialog --msgbox "BBR enabled successfully." 10 40
}

# 6. Function to enable Hybla
enable_hybla() {
  # Add lines to /etc/security/limits.conf
  echo "* soft nofile 51200" | sudo tee -a /etc/security/limits.conf
  echo "* hard nofile 51200" | sudo tee -a /etc/security/limits.conf

  # Run ulimit command
  ulimit -n 51200

  # Add lines to /etc/ufw/sysctl.conf
  echo "fs.file-max = 51200" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.core.rmem_max = 67108864" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.core.wmem_max = 67108864" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.core.netdev_max_backlog = 250000" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.core.somaxconn = 4096" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_tw_reuse = 1" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_tw_recycle = 0" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_fin_timeout = 30" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_keepalive_time = 1200" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.ip_local_port_range = 10000 65000" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_max_syn_backlog = 8192" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_max_tw_buckets = 5000" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_fastopen = 3" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_mem = 25600 51200 102400" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_rmem = 4096 87380 67108864" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_wmem = 4096 65536 67108864" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_mtu_probing = 1" | sudo tee -a /etc/ufw/sysctl.conf
  echo "net.ipv4.tcp_congestion_control = hybla" | sudo tee -a /etc/ufw/sysctl.conf

  dialog --msgbox "Hybla enabled successfully." 10 60
}

# 7. Function to enable and configure Cron
enable_and_configure_cron() {
  dialog --title "Enable and Configure Cron" --yesno "Would you like to enable and configure Cron? This will schedule automatic updates and system restarts every night at 01:00 +3:30 GMT." 10 60
  response=$?
  if [ $response -eq 0 ]; then
    echo "00 22 * * * /usr/bin/apt-get update && /usr/bin/apt-get upgrade -y && /usr/bin/apt-get autoremove -y && /usr/bin/apt-get autoclean -y && /usr/bin/apt-get clean -y" | sudo tee -a /etc/crontab
    echo "30 22 * * * /sbin/shutdown -r" | sudo tee -a /etc/crontab
    dialog --msgbox "Cron enabled and configured successfully." 10 40
  else
    dialog --msgbox "Cron configuration skipped." 10 40
  fi
}

# 8. Function to install Multiprotocol VPN Panel
install_vpn_panel() {
  dialog --title "Install Multiprotocol VPN Panel" --menu "Select a VPN Panel to Install:" 15 60 6 \
    "1" "X-UI | Alireza" \
    "2" "X-UI | MHSanaei" \
    "3" "X-UI | vaxilu" \
    "4" "X-UI | FranzKafkaYu" \
    "5" "X-UI En | FranzKafkaYu" \
    "6" "reality-ezpz | aleskxyz" 2> vpn_choice.txt

  vpn_choice=$(cat vpn_choice.txt)

  case $vpn_choice in
    "1")
      bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
      ;;
    "2")
      bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
      ;;
    "3")
      bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
      ;;
    "4")
      bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
      ;;
    "5")
      bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install_en.sh)
      ;;
    "6")
      bash <(curl -sL https://raw.githubusercontent.com/aleskxyz/reality-ezpz/master/reality-ezpz.sh)
      ;;
    *)
      dialog --msgbox "Invalid choice. No VPN Panel installed." 10 40
      return
      ;;
  esac

  # Wait for the user to press Enter
  read -p "Please press Enter to continue."

  # Return to the menu
}

# 9. Function to obtain SSL certificates
obtain_ssl_certificates() {
  apt install -y certbot
  dialog --title "Obtain SSL Certificates" --yesno "Do you want to Get SSL Certificates?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    dialog --title "SSL Certificate Information" --inputbox "Enter your email:" 10 60 2> email.txt
    email=$(cat email.txt)
    dialog --title "SSL Certificate Information" --inputbox "Enter your domain (e.g., sub.domain.com):" 10 60 2> domain.txt
    domain=$(cat domain.txt)

    if [ -n "$email" ] && [ -n "$domain" ]; then
      sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email "$email" -d "$domain"

      # Wait for the user to press Enter
      read -p "Press Enter to continue"

      dialog --msgbox "SSL certificates obtained successfully for $domain in /etc/letsencrypt/live." 10 60
    else
      dialog --msgbox "Both email and domain are required to obtain SSL certificates." 10 60
    fi
  else
    dialog --msgbox "Skipping SSL certificate acquisition." 10 40
  fi

  # Return to the menu
}

# Function to set up Pi-Hole
setup_pi_hole() {
  curl -sSL https://install.pi-hole.net | bash

  dialog --title "Change Pi-Hole Web Interface Password" --yesno "Do you want to change the Pi-Hole web interface password?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    pihole -a -p
    dialog --msgbox "Pi-Hole web interface password changed successfully." 10 60
  else
    dialog --msgbox "Skipping Pi-Hole web interface password change." 10 40
  fi

  if [ -f /etc/lighttpd/lighttpd.conf ]; then
    dialog --title "Change Lighttpd Port" --yesno "If you have installed Pi-Hole, then Lighttpd is listening on port 80 by default. Do you want to change the Lighttpd port?" 10 60
    response=$?
    if [ $response -eq 0 ]; then
      sudo nano /etc/lighttpd/lighttpd.conf
      dialog --msgbox "Lighttpd port changed." 10 60
    else
      dialog --msgbox "Skipping Lighttpd port change." 10 40
    fi
  fi
}

# Function to change SSH port
change_ssh_port() {
  # Prompt the user for the new SSH port
  dialog --title "Change SSH Port" --inputbox "Enter the new SSH port:" 10 60 2> ssh_port.txt
  new_ssh_port=$(cat ssh_port.txt)

  # Verify that a valid port number is provided
  if [[ $new_ssh_port =~ ^[0-9]+$ ]]; then
    # Remove the '#' comment from the 'Port' line in sshd_config (if present)
    sudo sed -i "/^#*Port/s/^#*Port/Port/" /etc/ssh/sshd_config

    # Update SSH port in sshd_config
    sudo sed -i "s/^Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config

    # Reload SSH service to apply changes
    sudo systemctl reload sshd

    dialog --msgbox "SSH port changed to $new_ssh_port. Please make sure to update your SSH client configuration." 10 60
  else
    dialog --msgbox "Invalid port number. Please provide a valid port." 10 60
  fi
}

# Function to enable UFW
enable_ufw() {
  # Set defaults
  sudo ufw default deny incoming
  sudo ufw default allow outgoing

  # Prompt the user for the SSH port to allow
  dialog --title "Enable UFW - SSH Port" --inputbox "Enter the SSH port to allow:" 10 60 2> ssh_port.txt
  ssh_port=$(cat ssh_port.txt)

  # Allow SSH port
  if [ -n "$ssh_port" ]; then
    sudo ufw allow "$ssh_port"/tcp
    sudo ufw limit "$ssh_port"/tcp
  fi

  # Prompt the user for additional ports to open
  dialog --title "Enable UFW - Additional Ports" --inputbox "Enter additional ports to open (comma-separated, e.g., 80,443):" 10 60 2> ufw_ports.txt
  ufw_ports=$(cat ufw_ports.txt)

  # Allow additional ports specified by the user
  if [ -n "$ufw_ports" ]; then
    IFS=',' read -ra ports_array <<< "$ufw_ports"
    for port in "${ports_array[@]}"; do
      sudo ufw allow "$port"
    done
  fi

  # Enable UFW to start at boot
  sudo ufw enable
  sudo systemctl enable ufw
}

# Function to install and configure WARP Proxy
install_configure_warp_proxy() {
  dialog --title "Install & Configure WARP Proxy" --yesno "Do you want to install and configure WARP Proxy?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    bash <(curl -fsSL git.io/warp.sh) proxy
    dialog --msgbox "WARP Proxy installed and configured successfully." 10 60
  else
    dialog --msgbox "Skipping installation and configuration of WARP Proxy." 10 60
  fi
}

# Function to deploy Erlang MTProto Proxy
deploy_erlang_mtproto_proxy() {
  curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh
}

# Function to setup Hysteria II
setup_hysteria_ii() {
  bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/Hysteria-Installer/main/hysteria.sh)
}

# Function to setup TUIC v5
setup_tuic_v5() {
  bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/tuic-v5-installer/main/tuic-installer.sh)
}

# Function to reboot the system
reboot_system() {
  dialog --title "Reboot System" --yesno "Do you want to reboot the system?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    sudo reboot
  else
    dialog --msgbox "System reboot canceled." 10 40
  fi
}

# Main menu
while true; do
  menu_choice=$(dialog --clear \
    --backtitle "[FreeIRAN]" \
    --title "FreeIRAN - Server Setup Script" \
    --menu "Select an option:" 15 60 16 \
    "1" "Update & Upgrade Server" \
    "2" "Install Essential Packages" \
    "3" "Install Speedtest" \
    "4" "Create SWAP File (if needed)" \
    "5" "Enable BBR" \
    "6" "Schedule Automatic Updates & ReStarts" \
    "7" "Install Multiprotocol VPN Panel" \
    "8" "Obtain SSL Certificates" \
    "9" "Set Up Pi-Hole" \
    "10" "Install & Configure WARP Proxy" \
    "11" "Deploy Erlang MTProto Proxy" \
    "12" "Setup Hysteria II" \
    "13" "Setup TUIC v5" \
    "14" "Change SSH Port" \
    "15" "Enable UFW (Uncomplicated Firewall)" \
    "16" "Reboot System" \
    3>&1 1>&2 2>&3)
  
  exit_status=$?
  if [ $exit_status -ne 0 ]; then
    clear
    exit 0
  fi

  case $menu_choice in
    "1")
      update_and_upgrade
      ;;
    "2")
      install_essential_packages
      ;;
    "3")
      install_speedtest
      ;;
    "4")
      create_swap_file
      ;;
    "5")
      enable_bbr
    "6")
      enable_hybla
      ;;
    "6")
      enable_and_configure_cron
      ;;
    "7")
      install_vpn_panel
      ;;
    "8")
      obtain_ssl_certificates
      ;;
    "9")
      setup_pi_hole
      ;;
    "10")
      install_configure_warp_proxy
      ;;
    "11")
      deploy_erlang_mtproto_proxy
      ;;
    "12")
      setup_hysteria_ii
      ;;
    "13")
      setup_tuic_v5
      ;;
    "14")
      change_ssh_port
      ;;
    "15")
      enable_ufw
      ;;
    "16")
      reboot_system
      ;;
  esac
done
