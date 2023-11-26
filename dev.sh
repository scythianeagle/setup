#!/bin/bash

# FreeIRAN v1.4.0
# -----------------------------------------------------------------------------
# Description: This script automates the setup and configuration of various
#              utilities and services on a Linux server for a secure and
#              optimized environment, with a focus on enhancing internet
#              freedom and privacy in Iran.
#
# Author: Erfan Namira
# GitHub: https://github.com/ErfanNamira/FreeIRAN
#
# Disclaimer: This script is provided for educational and informational
#             purposes only. Use it responsibly and in compliance with all
#             applicable laws and regulations.
#
# Note: Make sure to review and understand each section of the script before
#       running it on your system. Some configurations may require manual
#       adjustments based on your specific needs and server setup.
# -----------------------------------------------------------------------------

# Function to check for sudo privileges
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        if ! sudo -n true 2>/dev/null; then
            echo "This script must be run with sudo privileges."
            exit 1
        fi
    fi
}

display_intro() {
    clear
    echo "Welcome to FreeIRAN Setup Script v1.4.0"
    echo "---------------------------------------"
    echo "This script will configure various utilities and services"
    echo "to enhance internet freedom and privacy in Iran."
    echo ""
    echo "Please review the disclaimer and script description before proceeding."
    echo ""
    echo "WARNING: Some steps, installations, system changes, and configurations"
    echo "made by this script may be irreversible and cannot be reverted back to"
    echo "the initial state. Proceed with caution and review each action carefully."
    echo ""
}

# Function for error handling and input validation
validate_input() {
    read -rp "Would you kindly confirm your understanding and agreement to the disclaimer? (y/n): " choice
    case $choice in
        [Yy])
            execute_setup
            ;;
        [Nn])
            echo "Exiting script. No changes were made."
            exit 0
            ;;
        *)
            echo "Invalid input. Please enter 'y' or 'n'."
            validate_input
            ;;
    esac
}

# Function to execute setup based on user confirmation
execute_setup() {
    echo "Executing setup..."
    echo "Setup completed successfully!"
}

# Main function to run the script
main() {
    check_sudo
    display_intro
    validate_input
}

# 1. Function to perform system updates and cleanup
system_update() {
    local confirm_update
    confirm_update=$(dialog --clear --title "System Update and Cleanup" --yesno "This operation will update your system and remove unnecessary packages. Do you want to proceed?" 10 60 3>&1 1>&2 2>&3)

    if [[ $confirm_update == "0" ]]; then
        echo "Performing system update and cleanup..."
        sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y && sudo apt clean -y

        dialog --clear --msgbox "System updates and cleanup completed." 10 60
    else
        dialog --clear --msgbox "System updates and cleanup operation canceled." 10 60
    fi
}

# 2. Function to install Speedtest
install_speedtest() {
    local install_speedtest_prompt
    install_speedtest_prompt=$(dialog --clear --title "Install Speedtest" --yesno "Do you want to install Speedtest?" 10 60 3>&1 1>&2 2>&3)

    if [[ $install_speedtest_prompt == "0" ]]; then
        dialog --clear --infobox "Installing Speedtest. Please wait..." 10 60
        # Install Speedtest CLI
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
        sudo apt-get -y install speedtest

        dialog --clear --msgbox "Speedtest has been installed successfully. You can now run it by entering 'speedtest' in the terminal." 10 60
    else
        dialog --clear --msgbox "Skipping installation of Speedtest." 10 60
    fi
}

# 3. Function to create a SWAP file
create_swap_file() {
    local swap_size_file
    swap_size_file=$(mktemp /tmp/swap_size.XXXXXX)
    dialog --title "Create SWAP File" --yesno "Do you want to create a SWAP file?" 10 60

    if [ $? -eq 0 ]; then
        if [ -f /swapfile ]; then
            dialog --title "Swap File" --msgbox "A SWAP file already exists. Skipping swap file creation." 10 60
        else
            dialog --title "Swap File" --inputbox "Enter the size of the SWAP file (e.g., 2G for 2 gigabytes):" 10 60 2> "$swap_size_file"
            local swap_size=$(<"$swap_size_file")

            if [[ "$swap_size" =~ ^[0-9]+[GgMm]$ ]]; then
                dialog --infobox "Creating SWAP file. Please wait..." 10 60
                sudo fallocate -l "$swap_size" /swapfile
                sudo chmod 600 /swapfile
                sudo mkswap /swapfile
                sudo swapon /swapfile
                echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
                sudo sysctl vm.swappiness=10
                sudo sysctl vm.vfs_cache_pressure=50
                echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
                echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
                dialog --msgbox "SWAP file created successfully with a size of $swap_size." 10 60
            else
                dialog --msgbox "Invalid SWAP file size. Please provide a valid size (e.g., 2G for 2 gigabytes)." 10 60
            fi
        fi
    else
        dialog --msgbox "Skipping SWAP file creation." 10 60
    fi
    rm "$swap_size_file" # Clean up temporary file
}

# 4. Function to enable BBR
enable_bbr() {
  dialog --title "Enable BBR" --yesno "Do you want to enable BBR congestion control?\n\nEnabling BBR while Hybla is enabled can lead to conflicts. Are you sure you want to proceed?" 12 60
  response=$?
  if [ $response -eq 0 ]; then
    # Add BBR settings to sysctl.conf
    echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
    
    # Apply the new settings
    sudo sysctl -p

    dialog --msgbox "BBR congestion control has been enabled successfully." 10 60
  else
    dialog --msgbox "BBR configuration skipped." 10 60
  fi
}

# 5. Function to enable Hybla
enable_hybla() {
  dialog --title "Enable Hybla" --yesno "Do you want to enable Hybla congestion control?\n\nEnabling Hybla while BBR is enabled can lead to conflicts. Are you sure you want to proceed?" 12 60
  response=$?
  if [ $response -eq 0 ]; then
    # Add lines to /etc/security/limits.conf
    echo "* soft nofile 51200" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 51200" | sudo tee -a /etc/security/limits.conf

    # Run ulimit command
    ulimit -n 51200

    # Add lines to /etc/ufw/sysctl.conf
    sysctl_settings=(
      "fs.file-max = 51200"
      "net.core.rmem_max = 67108864"
      "net.core.wmem_max = 67108864"
      "net.core.netdev_max_backlog = 250000"
      "net.core.somaxconn = 4096"
      "net.ipv4.tcp_syncookies = 1"
      "net.ipv4.tcp_tw_reuse = 1"
      "net.ipv4.tcp_tw_recycle = 0"
      "net.ipv4.tcp_fin_timeout = 30"
      "net.ipv4.tcp_keepalive_time = 1200"
      "net.ipv4.ip_local_port_range = 10000 65000"
      "net.ipv4.tcp_max_syn_backlog = 8192"
      "net.ipv4.tcp_max_tw_buckets = 5000"
      "net.ipv4.tcp_fastopen = 3"
      "net.ipv4.tcp_mem = 25600 51200 102400"
      "net.ipv4.tcp_rmem = 4096 87380 67108864"
      "net.ipv4.tcp_wmem = 4096 65536 67108864"
      "net.ipv4.tcp_mtu_probing = 1"
      "net.ipv4.tcp_congestion_control = hybla"
    )

    for setting in "${sysctl_settings[@]}"; do
      echo "$setting" | sudo tee -a /etc/ufw/sysctl.conf
    done

    dialog --msgbox "Hybla congestion control has been enabled successfully." 10 60
  else
    dialog --msgbox "Hybla configuration skipped." 10 60
  fi
}

# 6. Function to Install Multiprotocol VPN Panel
install_vpn_panel() {
  local vpn_choice_file
  vpn_choice_file=$(mktemp /tmp/vpn_choice.XXXXXX)

  dialog --title "Install Multiprotocol VPN Panel" --menu "Select a VPN Panel to Install:" 15 60 8 \
    "1" "X-UI | Alireza" \
    "2" "X-UI | MHSanaei" \
    "3" "X-UI | vaxilu" \
    "4" "X-UI | FranzKafkaYu" \
    "5" "X-UI En | FranzKafkaYu" \
    "6" "reality-ezpz | aleskxyz" \
    "7" "Hiddify" \
    "8" "Marzban | Gozargah" 2> "$vpn_choice_file"

  local vpn_choice=$(<"$vpn_choice_file")

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
    "7")
      bash -c "$(curl -Lfo- https://raw.githubusercontent.com/hiddify/hiddify-config/main/common/download_install.sh)"
      ;;
    "8")
      sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install
      marzban cli admin create --sudo
      ;;
    *)
      dialog --msgbox "Invalid choice. No VPN Panel installed." 10 40
      rm "$vpn_choice_file"
      return
      ;;
  esac

  # Wait for the user to press Enter
  read -p "Please press Enter to continue."

  rm "$vpn_choice_file"
}

# 7. Function to obtain SSL certificates
obtain_ssl_certificates() {
  apt install -y certbot xclip
  dialog --title "Obtain SSL Certificates" --yesno "Do you want to Get SSL Certificates?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    local email_file="/tmp/email.txt"
    local domain_file="/tmp/domain.txt"

    xclip -selection clipboard -out > "$email_file"
    dialog --title "SSL Certificate Information" --inputbox "Enter your email (Ctrl+Shift+V to paste):" 10 60 "$(cat "$email_file")" 2> "$email_file"
    email=$(cat "$email_file")

    xclip -selection clipboard -out > "$domain_file"
    dialog --title "SSL Certificate Information" --inputbox "Enter your domain (e.g., sub.domain.com) (Ctrl+Shift+V to paste):" 10 60 "$(cat "$domain_file")" 2> "$domain_file"
    domain=$(cat "$domain_file")

    if [ -n "$email" ] && [ -n "$domain" ]; then
      sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email "$email" -d "$domain"

      # Wait for the user to press Enter
      read -p "Please Press Enter to continue"

      dialog --msgbox "SSL certificates obtained successfully for $domain in /etc/letsencrypt/live." 10 60
    else
      dialog --msgbox "Both email and domain are required to obtain SSL certificates." 10 60
    fi

    # Clean up temporary files
    rm "$email_file" "$domain_file"
  else
    dialog --msgbox "Skipping SSL certificate acquisition." 10 40
  fi

  # Return to the menu
}

# 8. Function to set up Pi-Hole
setup_pi_hole() {
  # Provide information about Pi-Hole and its benefits
  dialog --title "Install Pi-Hole" --yesno "Pi-Hole is a network-wide ad blocker that can enhance your online experience by blocking ads at the network level. Do you want to install Pi-Hole?" 12 60
  response=$?

  if [ $response -eq 0 ]; then
    # Install Pi-Hole
    curl -sSL https://install.pi-hole.net | bash

    # Ask if the user wants to change the Pi-Hole web interface password
    dialog --title "Change Pi-Hole Web Interface Password" --yesno "Do you want to change the Pi-Hole web interface password?" 10 60
    response=$?
    if [ $response -eq 0 ]; then
      pihole -a -p
      dialog --msgbox "Pi-Hole web interface password changed successfully." 10 60
    else
      dialog --msgbox "Skipping Pi-Hole web interface password change." 10 40
    fi

    # Ask if the user wants to change the Lighttpd port
    if [ -f /etc/lighttpd/lighttpd.conf ]; then
      dialog --title "Change Lighttpd Port" --yesno "Pi-Hole uses Lighttpd, which listens on port 80 by default. Do you want to change the Lighttpd port?" 10 60
      response=$?
      if [ $response -eq 0 ]; then
        sudo nano /etc/lighttpd/lighttpd.conf
        dialog --msgbox "Lighttpd port changed successfully." 10 60
      else
        dialog --msgbox "Skipping Lighttpd port change." 10 40
      fi
    fi
  else
    dialog --msgbox "Skipping Pi-Hole installation." 10 40
  fi
}

# 9. Function to change SSH port
change_ssh_port() {
  # Provide information about changing SSH port
  dialog --title "Change SSH Port" --msgbox "Changing the SSH port can enhance security by reducing automated SSH login attempts. However, it's essential to choose a port that is not already in use and to update your SSH client configuration accordingly.\n\nPlease consider the following:\n- Choose a port number between 1025 and 49151 (unprivileged ports).\n- Avoid well-known ports (e.g., 22, 80, 443).\n- Ensure that the new port is open in your firewall rules.\n- Update your SSH client configuration to use the new port." 14 80

  # Prompt the user for the new SSH port
  dialog --title "Enter New SSH Port" --inputbox "Enter the new SSH port:" 10 60 2> ssh_port.txt
  new_ssh_port=$(cat ssh_port.txt)

  # Verify that a valid port number is provided
  if [[ $new_ssh_port =~ ^[0-9]+$ ]]; then
    # Remove the '#' comment from the 'Port' line in sshd_config (if present)
    sudo sed -i "/^#*Port/s/^#*Port/Port/" /etc/ssh/sshd_config

    # Update SSH port in sshd_config
    sudo sed -i "s/^Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config

    # Reload SSH service to apply changes
    sudo systemctl reload sshd

    dialog --msgbox "SSH port changed to $new_ssh_port. Ensure that you apply related firewall rules and update your SSH client configuration accordingly." 12 60
  else
    dialog --msgbox "Invalid port number. Please provide a valid port." 10 60
  fi

  # Clean up temporary files
  rm -f ssh_port.txt
}

# 10. Function to enable UFW
enable_ufw() {
  # Set UFW defaults
  sudo ufw default deny incoming
  sudo ufw default allow outgoing

  # Prompt the user for the SSH port to allow
  ssh_port=$(dialog --title "Enable UFW - SSH Port" --inputbox "Enter the SSH port to allow (default is 22):" 10 60 2>&1)

  # Check if the SSH port is empty and set it to default (22) if not provided
  if [ -z "$ssh_port" ]; then
    ssh_port=22
  fi

  # Allow SSH port
  sudo ufw allow "$ssh_port/tcp"

  # Prompt the user for additional ports to open
  ufw_ports=$(dialog --title "Enable UFW - Additional Ports" --inputbox "Enter additional ports to open (comma-separated, e.g., 80,443):" 10 60 2>&1)

  # Allow additional ports specified by the user
  if [ -n "$ufw_ports" ]; then
    IFS=',' read -ra ports_array <<< "$ufw_ports"
    for port in "${ports_array[@]}"; do
      sudo ufw allow "$port/tcp"
    done
  fi

  # Enable UFW to start at boot
  sudo ufw --force enable
  sudo systemctl enable ufw

  # Display completion message
  dialog --msgbox "UFW enabled and configured successfully.\nSSH port $ssh_port and additional ports allowed." 12 60

  # Clean up temporary files
  rm -f ssh_port.txt ufw_ports.txt
}

# 11. Function to install and configure WARP Proxy
install_configure_warp_proxy() {
  dialog --title "Install & Configure WARP Proxy" --yesno "Do you want to install and configure WARP Proxy?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    bash <(curl -fsSL git.io/warp.sh) proxy
    
    # Wait for the user to press Enter
    read -p "Please Press Enter to continue"
    
    dialog --msgbox "WARP Proxy installed and configured successfully." 10 60
  else
    dialog --msgbox "Skipping installation and configuration of WARP Proxy." 10 60
  fi
  
  # Clean up temporary files (if any)
  rm -f warp_proxy_temp_file
}

# 12. Function to set up MTProto Proxy submenu
setup_mtproto_proxy_submenu() {
  local mtproto_choice
  mtproto_choice=$(dialog --title "Setup MTProto Proxy" --menu "Choose an MTProto Proxy option:" 15 60 6 \
    1 "Setup Erlang MTProto (recommended) | Sergey Prokhorov" \
    2 "Setup/Manage Python MTProto | HirbodBehnam" \
    3 "Setup/Manage Official MTProto | HirbodBehnam" \
    4 "Setup/Manage Golang MTProto | HirbodBehnam" 2>&1 >/dev/tty)

  case $mtproto_choice in
    "1")
      # Setup Erlang MTProto
      bash <(curl -fsSL https://git.io/fj5ru)
      ;;
    "2")
      # Setup/Manage Python MTProto
      bash <(curl -fsSL https://git.io/fjo34)
      ;;
    "3")
      # Setup/Manage Official MTProto
      bash <(curl -fsSL https://git.io/fjo3u)
      ;;
    "4")
      # Setup/Manage Golang MTProto
      bash <(curl -fsSL https://git.io/mtg_installer)
      ;;
    *)
      dialog --msgbox "Invalid choice. No MTProto Proxy setup performed." 10 40
      return
      ;;
  esac

  # Wait for the user to press Enter
  read -p "Please press Enter to continue."
}

# Function to set up MTProto Proxy
setup_mtproto_proxy() {
  dialog --title "Setup MTProto Proxy" --yesno "Do you want to set up an MTProto Proxy? It is recommended to install only one of these options. Installing multiple options may lead to conflicts." 10 60
  response=$?
  if [ $response -eq 0 ]; then
    setup_mtproto_proxy_submenu
  else
    dialog --msgbox "Skipping MTProto Proxy setup." 10 40
  fi
}

# 13. Function to setup Hysteria II
setup_hysteria_ii() {
  bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/Hysteria-Installer/main/hysteria.sh)

  # Wait for the user to press Enter
  read -p "Please Press Enter to continue"
}

# 14. Function to setup TUIC v5
setup_tuic_v5() {
  bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/tuic-v5-installer/main/tuic-installer.sh)

  # Wait for the user to press Enter
  read -p "Please Press Enter to continue"
}

# 15. Function to setup Juicity
setup_juicity() {
  dialog --title "Setup Juicity" --yesno "Do you want to setup Juicity?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    bash <(curl -fsSL https://raw.githubusercontent.com/deathline94/Juicity-Installer/main/juicity-installer.sh)
    read -p "Juicity setup completed. Please Press Enter to continue."
  else
    dialog --msgbox "Skipping Juicity setup." 10 40
  fi
}

# 16. Function to setup WireGuard
setup_wireguard_angristan() {
  dialog --title "Setup WireGuard | angristan" --yesno "Do you want to set up WireGuard using angristan's script?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    # Download and execute the WireGuard installation script
    curl -fsSL https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh -o wireguard-install.sh
    chmod +x wireguard-install.sh
    ./wireguard-install.sh

    # Wait for the user to press Enter
    read -p "Please press Enter to continue."
  else
    dialog --msgbox "Skipping WireGuard installation." 10 40
  fi
}

# 17. Function to setup OpenVPN
setup_openvpn_angristan() {
  dialog --title "Setup OpenVPN | angristan" --yesno "Do you want to set up OpenVPN using angristan's script?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    # Download and execute the OpenVPN installation script
    curl -fsSL https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh -o openvpn-install.sh
    chmod +x openvpn-install.sh
    ./openvpn-install.sh

    # Wait for the user to press Enter
    read -p "Please press Enter to continue."
  else
    dialog --msgbox "Skipping OpenVPN installation." 10 40
  fi
}

# 18. Function to setup IKEv2/IPsec
setup_ikev2_ipsec() {
  dialog --title "Setup IKEv2/IPsec" --yesno "Do you want to set up IKEv2/IPsec?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    # Download and execute the IKEv2/IPsec installation script
    curl -fsSL https://get.vpnsetup.net -o vpn.sh && sudo sh vpn.sh

    # Wait for the user to press Enter
    read -p "Please press Enter to continue."
  else
    dialog --msgbox "Skipping IKEv2/IPsec setup." 10 40
  fi
}

# 19. Function to create a non-root SSH user
create_ssh_user() {
  # Ask the user for the username
  dialog --title "Create SSH User" --inputbox "Enter the username for the new SSH user:" 10 60 2> username.txt
  username=$(cat username.txt)

  # Check if the username is empty
  if [ -z "$username" ]; then
    dialog --msgbox "Username cannot be empty. SSH user creation aborted." 10 60
    return
  fi

  # Ask the user for a secure password
  password=$(dialog --title "Create SSH User" --passwordbox "Enter a strong password for the new SSH user:" 10 60 2>&1)

  # Check if the password is empty
  if [ -z "$password" ]; then
    dialog --msgbox "Password cannot be empty. SSH user creation aborted." 10 60
    return
  fi

  # Create the user with the specified username
  sudo useradd -m -s /bin/bash "$username"

  # Set the user's password securely
  echo "$username:$password" | sudo chpasswd

  # Display the created username to the user
  dialog --title "SSH User Created" --msgbox "SSH user '$username' has been created successfully.\n\nUsername: $username" 12 60
}

# 20. Function to reboot the system
reboot_system() {
  dialog --title "Reboot System" --yesno "Do you want to reboot the system?" 10 60
  response=$?
  if [ $response -eq 0 ]; then
    dialog --infobox "Rebooting the system..." 5 30
    sleep 2  # Display the message for 2 seconds before rebooting
    sudo reboot
  else
    dialog --msgbox "System reboot canceled." 10 40
  fi
}

# 21. Function to exit the script
exit_script() {
  clear  # Clear the terminal screen for a clean exit
  echo "Exiting the script. Goodbye!"
  exit 0  # Exit with a status code of 0 (indicating successful termination)
}

# Function to display the menu
display_menu() {
    local choice
    while true; do
        choice=$(dialog --clear \
                        --backtitle "FreeIRAN Setup Script v1.4.0" \
                        --title "Menu" \
                        --menu "Choose an option:" 20 60 15 \
                        "1" "Optimize System" \
                        "2" "Install Speedtest" \
                        "3" "Create SWAP" \
                        "4" "Enable BBR" \
                        "5" "Enable Hybla" \
                        "6" "Install VPN Panel" \
                        "7" "Get SSL Certificates" \
                        "8" "Set up Pi-Hole" \
                        "9" "Change SSH port" \
                        "10" "Enable FireWall" \
                        "11" "Install WARP" \
                        "12" "Manage MTProto Proxy" \
                        "13" "Manage Hysteria II" \
                        "14" "Manage TUIC v5" \
                        "15" "Manage Juicity" \
                        "16" "Manage WireGuard" \
                        "17" "Manage OpenVPN" \
                        "18" "Setup IKEv2/IPsec" \
                        "19" "Create SSH user" \
                        "20" "Reboot the system" \
                        "21" "Exit script" 3>&1 1>&2 2>&3)
        case $choice in
            1) system_update ;;
            2) install_speedtest ;;
            3) create_swap_file ;;
            4) enable_bbr ;;
            5) enable_hybla ;;
            6) install_vpn_panel ;;
            7) obtain_ssl_certificates ;;
            8) setup_pi_hole ;;
            9) change_ssh_port ;;
            10) enable_ufw ;;
            11) install_configure_warp_proxy ;;
            12) setup_mtproto_proxy ;;
            13) setup_hysteria_ii ;;
            14) setup_tuic_v5 ;;
            15) setup_juicity ;;
            16) setup_wireguard_angristan ;;
            17) setup_openvpn_angristan ;;
            18) setup_ikev2_ipsec ;;
            19) create_ssh_user ;;
            20) reboot_system ;;
            21) exit_script ;;
            *) echo "Invalid option";;
        esac
    done
}

# Execute the main function
main() {
    check_sudo
    display_intro
    validate_input
    display_menu
}

# Execute the script
main
