# {{CLIENT_EMAIL}}

[Interface]
PrivateKey = {{CLIENT_PRIVATE_KEY}}
Address = {{CLIENT_IP}}
DNS = 1.1.1.1

[Peer]
PublicKey = {{SERVER_PUBLIC_KEY}}
Endpoint = {{ENDPOINT}}
AllowedIPs = {{ALLOWED_IPS}}
PersistentKeepalive = 25
