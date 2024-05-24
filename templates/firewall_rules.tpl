ufw default deny incoming comment 'Block all external connections'
ufw default allow outgoing comment 'Allow all outgoing connections'
ufw allow {{WG_PORT}}/udp comment 'Allow WireGuard Connections'
ufw allow in on {{WG_INTERFACE}} comment 'Allow Connections via WireGuard Interface'
ufw allow from {{WG_SUBNET}} to any port {{SSH_PORT}} proto tcp comment 'Allow SSH via WireGuard'

# ufw allow from {{WG_SUBNET}} to any port 5432 proto tcp comment 'Allow PostgreSQL via WireGuard'
# ufw allow from {{WG_SUBNET}} to any port 6379 proto tcp comment 'Allow Redis via WireGuard'
# ufw allow from x.x.x.x to any port 3000:3010 proto tcp comment 'Allow ports from 3000 to 3010 via SRVx'

# ufw allow 80/tcp comment 'Allow HTTP'
# ufw allow 443/tcp comment 'Allow HTTPS'
