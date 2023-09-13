# FreeIRAN
One Script for setup Ubuntu Server

Don't forget to:

1. Add your desired adlists via Pi-hole web interface
2. Update Pi-hole Database with []
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
