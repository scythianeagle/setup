# A Simple Guide for Manually Setting Up an Ubuntu Server
### Perform system updates and cleanup
```
sudo apt-get install screen
screen
screen -list
screen -raAd
```
```
apt update && apt upgrade -y && apt autoremove -y && apt autoclean && apt clean
```
```
sudo journalctl --vacuum-size=50M
```
### Install essential packages
```
sudo add-apt-repository universe
```
```
sudo apt install -y curl nano certbot cron ufw htop dialog
```
### Install Speedtest
```
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
speedtest
```
### Create a SWAP file
```
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
sudo nano /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
```
