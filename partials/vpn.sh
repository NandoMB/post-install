#!/usr/bin/env bash

# Server
VPN_SERVER_KEYS_PATH="/etc/wireguard/keys"
VPN_SERVER_PRIVATE_KEY_PATH="${VPN_SERVER_KEYS_PATH}/${VPN_CONFIGURE_PRIVATE_KEY_NAME}.key"
VPN_SERVER_PUBLIC_KEY_PATH="${VPN_SERVER_KEYS_PATH}/${VPN_CONFIGURE_PUBLIC_KEY_NAME}.pub"
VPN_SERVER_OUTPUT_FILE="/etc/wireguard/wg0.conf"

# Clients
VPN_CLIENTS_PATH="/etc/wireguard/clients"
VPN_CLIENT_KEY_NAME="${VPN_CREATE_USER_EMAIL//[^a-zA-Z0-9]/_}"
VPN_CLIENT_DIR="$VPN_CLIENTS_PATH/$VPN_CLIENT_KEY_NAME"
VPN_CLIENT_CONFIG_PATH="$VPN_CLIENT_DIR/${VPN_CLIENT_KEY_NAME}.conf"

#
# Configure
#
vpn_configure() {
  info "Configurando VPN..."
  
  info "Instalando WireGuard..."
  sudo apt update && sudo apt install -y wireguard

  vpn_configure_generate_keys

  vpn_configure_create_config_file

  if [[ "$VPN_CONFIGURE_ENABLE_IP_FORWARDING" == true ]]; then
    vpn_configure_enable_ip_forwarding
  fi
  
  info "Habilitando o serviço no systemctl..."
  sudo systemctl enable wg-quick@wg0
  sudo systemctl start wg-quick@wg0

  info "Status do WireGuard:"
  sudo wg show

  success "VPN configurado com sucesso."
}

vpn_configure_generate_keys() {
  sudo mkdir -p "$VPN_SERVER_KEYS_PATH"
  sudo chmod 700 "$VPN_SERVER_KEYS_PATH"

  if [[ -f $VPN_SERVER_PRIVATE_KEY_PATH ]]; then
    warn "Chaves já existem. Ignorando esta etapa..."
  else
    info "Gerando chaves do servidor..."
    sudo bash -c "cd $VPN_SERVER_KEYS_PATH && umask 077 && wg genkey | tee ${VPN_CONFIGURE_PRIVATE_KEY_NAME}.key | wg pubkey > ${VPN_CONFIGURE_PUBLIC_KEY_NAME}.pub"
  fi
}

vpn_configure_create_config_file() {
  local vpn_private_key=$(sudo cat "$VPN_SERVER_PRIVATE_KEY_PATH")
  local template="./templates/vpn_configure.tpl"
  local temp_file=$(mktemp)

  info "Gerando arquivo de configuração..."

  sed \
    -e "s|{{PRIVATE_KEY}}|$vpn_private_key|g" \
    -e "s|{{IP}}|$VPN_CONFIGURE_SERVER_IP|g" \
    -e "s|{{PORT}}|$VPN_CONFIGURE_PORT|g" \
    "$template" > "$temp_file"

  sudo cp "$temp_file" "$VPN_SERVER_OUTPUT_FILE"
  sudo chmod 600 "$VPN_SERVER_OUTPUT_FILE"
  rm "$temp_file"
}

vpn_configure_enable_ip_forwarding() {
  info "Ativando o encaminhamento de IP..."
  sudo sed -i 's|^#\?net.ipv4.ip_forward=.*|net.ipv4.ip_forward=1|' /etc/sysctl.conf

  if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  fi

  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sysctl -p
}

#
# Create User
#
vpn_create_user() {
  if [[ -z "$SERVER_PUBLIC_IP" ]]; then
    error "❌ O IP público fornecido é inválido. Abortando operação."
    exit 1
  fi

  if ! sudo test -f "$VPN_SERVER_PUBLIC_KEY_PATH"; then
    error "Chave pública do servidor não encontrada em: $VPN_SERVER_PUBLIC_KEY_PATH"
    error "Por favor, crie as chaves do servidor antes de prosseguir."
    exit 1
  fi

  info "Criando usuário VPN..."
  
  sudo mkdir -p $VPN_CLIENTS_PATH

  local total_of_clients=$(sudo find $VPN_CLIENTS_PATH/ -mindepth 1 -maxdepth 1 -type d | wc -l)
  local client_ip_number=$((VPN_CREATE_USER_FIRST_VALID_CLIENT_IP + total_of_clients))

  if [[ $client_ip_number -gt 254 ]]; then
    error "❌ O limite máximo suportado pela subnet foi atingido ($client_ip_number). Abortando operação."
    exit 1
  fi

  VPN_CLIENT_IP="${VPN_CONFIGURE_IPV4_OCTET_1}.${VPN_CONFIGURE_IPV4_OCTET_2}.${VPN_CONFIGURE_IPV4_OCTET_3}.${client_ip_number}/${VPN_CONFIGURE_IPV4_SUBNET}"

  success "IP atribuído ao usuário na VPN: $VPN_CLIENT_IP"

  vpn_create_user_generate_keys
  vpn_create_user_generate_config
  vpn_create_user_add_client_to_server
  vpn_create_user_apply_changes
  vpn_create_user_print_client_config

  success "Usuário VPN criado com sucesso."
}

vpn_create_user_generate_keys() {
  local client_private_key_path="$VPN_CLIENT_DIR/private.key"
  local client_public_key_path="$VPN_CLIENT_DIR/public.pub"

  sudo mkdir -p "$VPN_CLIENT_DIR"
  sudo chmod 700 "$VPN_CLIENT_DIR"

  info "Gerando chaves do cliente..."

  VPN_CLIENT_PRIVATE_KEY=$(wg genkey)
  echo "$VPN_CLIENT_PRIVATE_KEY" | sudo tee "$client_private_key_path" > /dev/null
  echo "$VPN_CLIENT_PRIVATE_KEY" | wg pubkey | sudo tee "$client_public_key_path" > /dev/null

  VPN_CLIENT_PUBLIC_KEY=$(sudo cat "$client_public_key_path")

  success "$VPN_CREATE_USER_EMAIL"
  success "Public Key: $client_public_key_path"
  success "Private Key: $client_private_key_path"
}

vpn_create_user_generate_config() {
  local template="./templates/vpn_create_user.tpl"
  local temp_file=$(mktemp)
  local server_public_key=$(sudo cat "$VPN_SERVER_PUBLIC_KEY_PATH")
  local endpoint="${SERVER_PUBLIC_IP}:${VPN_CONFIGURE_PORT}"
  local allowed_ips="$VPN_CONFIGURE_SERVER_NETWORK"
  
  info "Gerando arquivo de configuração do cliente..."

  sed \
    -e "s|{{CLIENT_EMAIL}}|$VPN_CREATE_USER_EMAIL|g" \
    -e "s|{{CLIENT_PRIVATE_KEY}}|$VPN_CLIENT_PRIVATE_KEY|g" \
    -e "s|{{CLIENT_IP}}|$VPN_CLIENT_IP|g" \
    -e "s|{{SERVER_PUBLIC_KEY}}|$server_public_key|g" \
    -e "s|{{ENDPOINT}}|$endpoint|g" \
    -e "s|{{ALLOWED_IPS}}|$allowed_ips|g" \
    "$template" > "$temp_file"

  sudo cp "$temp_file" "$VPN_CLIENT_CONFIG_PATH"
  sudo chmod 600 "$VPN_CLIENT_CONFIG_PATH"
  sudo rm "$temp_file"

  success "Arquivo de configuração criado com sucesso: $VPN_CLIENT_CONFIG_PATH"
}

vpn_create_user_add_client_to_server() {
  local template="./templates/vpn_create_user_peer.tpl"
  local temp_file=$(mktemp)

  info "Adicionando cliente ao arquivo do servidor WireGuard..."

  sed \
    -e "s|{{CLIENT_EMAIL}}|$VPN_CREATE_USER_EMAIL|g" \
    -e "s|{{CLIENT_PUBLIC_KEY}}|$VPN_CLIENT_PUBLIC_KEY|g" \
    -e "s|{{CLIENT_IP}}|$VPN_CLIENT_IP|g" \
    "$template" > "$temp_file"

  sudo bash -c "cat '$temp_file' >> '$VPN_SERVER_OUTPUT_FILE'"
  sudo rm "$temp_file"

  success "Cliente adicionado ao servidor: $VPN_SERVER_OUTPUT_FILE"
}

vpn_create_user_apply_changes() {
  info "Reiniciando WireGuard..."
  sudo systemctl restart wg-quick@wg0
  success "WireGuard reiniciado com sucesso!"
}

vpn_create_user_print_client_config() {
  info "Configuração do cliente:"
  echo "-----------------------------------"
  sudo cat "$VPN_CLIENT_CONFIG_FILE"
  echo "-----------------------------------"
  info "Configuração do server:"
  echo "-----------------------------------"
  sudo cat "$VPN_SERVER_OUTPUT_FILE"
  echo "-----------------------------------"
}
