#!/bin/bash

# Function to change the SSH port
change_ssh_port() {
    local new_ssh_port="$1"
    if [[ -n "$new_ssh_port" ]]; then
        sudo sed -i.bak "s/^Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config
        sudo systemctl restart sshd
        echo "SSH port updated to $new_ssh_port. Make sure to update your SSH client configuration."
    else
        echo "No valid SSH port provided. SSH port remains unchanged."
    fi
}

# Function to create and configure a swap file
create_swap_file() {
    local swap_size="$1"
    if [[ -n "$swap_size" ]]; then
        # Calculate the size in megabytes (1M blocks)
        local swap_size_mb=$((swap_size * 1024))

        # Create the swap file
        sudo dd if=/dev/zero of=/swapfile bs=1M count="$swap_size_mb"

        # Set permissions
        sudo chmod 600 /swapfile

        # Make it a swap file
        sudo mkswap /swapfile

        # Enable the swap file
        sudo swapon /swapfile

        # Add swap entry to /etc/fstab to make it persistent
        echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab

        echo "Swap file created and activated with a size of $swap_size MB."

        # Set vm.swappiness and vm.vfs_cache_pressure
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

        # Apply sysctl settings
        sudo sysctl -p
    else
        echo "No valid swap size provided. Swap settings remain unchanged."
    fi
}

# Ask the user for a new SSH port
read -p "Enter a new SSH port (e.g., 2222): " new_ssh_port
change_ssh_port "$new_ssh_port"

# Ask the user if they want to create a swap file
read -p "Do you want to create a swap file? (y/n): " create_swap

if [[ "$create_swap" == "y" || "$create_swap" == "Y" ]]; then
    # Ask the user for the size of the swap file in gigabytes
    read -p "Enter the size of the swap file in gigabytes (e.g., 1): " swap_size
    create_swap_file "$swap_size"
else
    echo "No swap file created. Swap settings remain unchanged."
fi

# Update package list, upgrade packages, remove unnecessary packages, clean package cache
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean && sudo apt clean
