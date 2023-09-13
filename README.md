# FreeIRAN 🕊️
🌟 A simple bash script for setup Ubuntu Server

What this scriptes do:
1. Update & Upgrade Server 🧬
2. Install essential packages 🎉
3. Install Speedtest 🚀
4. Create SWAP File 💾
5. Enable BBR 🛸
6. Enable and configure Cron 🏵️
7. Automatically update and restart the server every night at 01:00 GMT+3:30 🎗️
8. Install X-UI ❤️‍🔥
9. Install Pi-Hole Adblocker 💝
10. Change Local DNS to PiHole 🎯
11. Install WARP WireProxy ✨
12. Install Erlang MTProto Proxy 💫
13. Install Hysteria II 🌈
14. Install TUIC v5 🔥

⚠️ Manually set the parameters yourself when prompted during the setup.

# After setup has completed, don't forget to:

1. Add your desired adlists via Pi-hole web interface
```
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.txt
https://big.oisd.nl/
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/pro.txt
https://blocklistproject.github.io/Lists/abuse.txt
https://blocklistproject.github.io/Lists/ads.txt
https://blocklistproject.github.io/Lists/crypto.txt
https://blocklistproject.github.io/Lists/drugs.txt
https://blocklistproject.github.io/Lists/fraud.txt
https://blocklistproject.github.io/Lists/gambling.txt
https://blocklistproject.github.io/Lists/malware.txt
https://blocklistproject.github.io/Lists/phishing.txt
https://blocklistproject.github.io/Lists/ransomware.txt
https://blocklistproject.github.io/Lists/redirect.txt
https://blocklistproject.github.io/Lists/scam.txt
https://raw.githubusercontent.com/MasterKia/PersianBlocker/main/PersianBlockerHosts.txt
```
3. Update Pi-hole Database with
```
pihole -g
```
4. You can connect/disconnect WireProxy with
```
warp y
```
6. Obtain SSL Certificates with
```
sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email mymail@gmail.com -d sub.domain.com
```
8. Change SSH Port with
```
sudo nano /etc/ssh/sshd_config
sudo systemctl reload sshd
```
8. Setup UFW
```
sudo nano /etc/default/ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow SSHPORT/tcp
sudo ufw limit SSHPORT/tcp
sudo ufw allow PORT
sudo ufw enable
sudo ufw status verbose
sudo systemctl enable ufw
```
10. Restart your server with
```
sudo shutdown -r now
```
# Optional: Install qbittorrent-nox
```
sudo add-apt-repository ppa:qbittorrent-team/qbittorrent-stable
sudo apt update
sudo apt install qbittorrent-nox
sudo nano /etc/systemd/system/qbittorrent-nox.service
qbittorrent-nox
sudo adduser --system --group qbittorrent-nox
sudo adduser root qbittorrent-nox
sudo systemctl daemon-reload
sudo systemctl enable qbittorrent-nox
sudo systemctl start qbittorrent-nox
sudo systemctl status qbittorrent-nox
```
# Optional: Install simplefileserver
```
cd /home/qbittorrent-nox/Downloads
wget http://down.dxscx.com/simple-file-server_current_linux_amd64.tar.gz
tar -xzvf simple-file-server_current_linux_amd64.tar.gz
chmod 777 simplefileserver
sudo /home/qbittorrent-nox/Downloads/simplefileserver
```
# Optional: Warp XrayConfig
```
{
  "protocol": "socks",
  "settings": {
    "servers": [
      { 
        "address": "127.0.0.1",
        "port":1024
      }
    ]
  },
  "tag":"warp"
},
```
