# FreeIRAN
One Script for setup Ubuntu Server

Don't forget to:

1. Add your desired adlists via Pi-hole web interface
2. Update Pi-hole Database with [pihole -g]
3. You can connect/disconnect WireProxy with [warp y]
5. Obtain SSL Certificates with [sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email mymail@gmail.com -d sub.domain.com]
6. Change SSH Port with [sudo nano /etc/ssh/sshd_config]

sudo nano /etc/ssh/sshd_config   ctrl+o
sudo systemctl reload sshd

8. Setup UFW
9. Restart your server with [sudo shutdown -r now]
