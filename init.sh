#!/usr/bin/env bash

set -euo pipefail

# Load Environment Variables
source .env

# 
ACTIVE_USER="${SUDO_USER:-$USER}"
ACTIVE_USER_HOME=$(eval echo "~${ACTIVE_USER}")
SSH_PORT=${SSH_PORT:-22}
SSH_USER=${SSH_USER:-$ACTIVE_USER}

# Load Partials
source ./partials/common.sh
source ./partials/os_auto_update.sh
source ./partials/os_create_user.sh
source ./partials/os_create_user_config.sh
source ./partials/os_install_apps.sh
source ./partials/ssh.sh
source ./partials/vpn.sh
source ./partials/firewall.sh
source ./partials/fail2ban.sh

init() {
  check_envs

  if [[ "$OS_AUTO_UPDATE_ENABLE" == true ]]; then
    configure_os_updates
  fi

  if [[ "$USER_CREATION_ENABLE" == true ]]; then
    create_os_user
  fi
  
  if [[ "$USER_CONFIG_ENABLE" == true ]]; then
    create_os_config_user
  fi
  
  if [[ "$APP_INSTALL_ENABLE" == true ]]; then
    install_apps
  fi
  
  if [[ "$SSH_ENABLE" == true ]]; then
    if [[ "$SSH_CONFIGURE" == true ]]; then
      configure_ssh
    fi
    if [[ "$SSH_CREATE_USER" == true ]]; then
      create_ssh_user
    fi
  fi
  
  if [[ "$VPN_ENABLE" == true ]]; then
    if [[ "$VPN_CONFIGURE" == true ]]; then
      configure_vpn
    fi
    if [[ "$VPN_CREATE_USER" == true ]]; then
      create_vpn_user
    fi
  fi

  if [[ "$FIREWALL_ENABLE" == true ]]; then
    configure_firewall
  fi

  if [[ "$FAIL2BAN_ENABLE" == true ]]; then
    configure_fail2ban
  fi

  success "Configuração concluída com sucesso."
}

check_envs () {
  info "Checking required environment variables..."
  # require_env NOTIFICATION_WEBHOOK_URL
  # require_env BUCKET_NAME
  # require_env BUCKET_ENDPOINT
  # require_env BUCKET_ACCESS_KEY
  # require_env BUCKET_SECRET
  # require_env BUCKET_REGION
  # require_env CONTAINER_NAME
  # require_env DB_USER
  # require_env DB_PASSWORD
  # require_env DB_DATABASES

  require_env SERVER_NAME
  require_env SERVER_ID
  require_env SERVER_PUBLIC_IP

  require_env OS_AUTO_UPDATE_ENABLE
  require_env USER_CREATION_ENABLE
  require_env USER_CONFIG_ENABLE
  require_env APP_INSTALL_ENABLE
  require_env SSH_ENABLE
  require_env SSH_CONFIGURE
  require_env SSH_CREATE_USER
  require_env VPN_ENABLE
  require_env VPN_CONFIGURE
  require_env VPN_CREATE_USER
  require_env FIREWALL_ENABLE
  require_env FAIL2BAN_ENABLE
}

# 
# Configure OS
# 
configure_os_updates() {
  info "Updating packages..."
  os_auto_update_and_upgrade_packages
  info "Configuring automatic updates..."
  os_auto_update_configure_unattended_upgrades
  success "Automatic updates configured."
}

# 
# Create OS User
# 
create_os_user() {
  info "Validating os user creation environment variables..."
  require_env USER_CREATION_NAME
  require_env USER_CREATION_PASSWORD
  require_env USER_CREATION_ADD_TO_ADM
  require_env USER_CREATION_ADD_TO_SUDO
  require_env USER_CREATION_USE_AS_DEFAULT

  local USER_NAME="$USER_CREATION_NAME"
  local USER_PASSWORD="$USER_CREATION_PASSWORD"
  local USER_HOME=$(eval echo "~$USER_NAME")

  if ! id "$USER_NAME" &>/dev/null; then
    info "Criando o usuário $USER_NAME."
    os_create_user_new "$USER_NAME" "$USER_PASSWORD"
    success "Usuário $USER_NAME criado com sucesso."
  else
    warn "Usuário $USER_NAME já existe."
  fi

  if [[ "$USER_CREATION_ADD_TO_SUDO" == true ]]; then
    info "Adicionando o usuário $USER_NAME ao grupo sudo."
    os_create_user_add_to_group "$USER_NAME" "sudo"
  fi

  if [[ "$USER_CREATION_ADD_TO_ADM" == true ]]; then
    info "Adicionando o usuário $USER_NAME ao grupo adm."
    os_create_user_add_to_group "$USER_NAME" "adm"
  fi

  if [[ "$USER_CREATION_USE_AS_DEFAULT" == true ]]; then
    info "Trocando acesso para o usuário $USER_NAME"
    os_create_user_change_user "$USER_NAME"
  fi

  success "Inclusão de usuário concluída."
}

# 
# Create OS Config User
# 
create_os_config_user() {
  info "Validating os user config environment variables..."
  require_env USER_CONFIG_FILE_NAME
  require_env USER_CONFIG_FILE_PATH
  require_env USER_CONFIG_ADD_TO_BASHRC

  local CONFIG_FILE="$USER_CONFIG_FILE_PATH/$USER_CONFIG_FILE_NAME"
  local TEMPLATE_PATH="./templates/os_create_user_config.tpl"

  os_create_user_config_validate "$TEMPLATE_PATH"
  info "Gerando arquivo de configuração..."
  os_create_user_config_build_file "$CONFIG_FILE" "$TEMPLATE_PATH"
  success "Arquivo de configuração criado com sucesso: $CONFIG_FILE"
  os_create_user_config_add_to_bashrc "$CONFIG_FILE"
  success "Configuração concluída e carregada automaticamente."
}

# 
# Install Apps
# 
install_apps() {
  info "Validating app install environment variables..."
  require_env APP_INSTALL_RSYNC
  require_env APP_INSTALL_GIT
  require_env APP_INSTALL_NEOFETCH
  require_env APP_INSTALL_NVM
  require_env APP_INSTALL_PM2
  require_env APP_INSTALL_DOCKER
  require_env APP_INSTALL_AWS_CLI

  info "Iniciando a instalação de aplicativos..."
  sudo apt update

  if [[ "$APP_INSTALL_RSYNC" == true ]]; then
    os_install_apps_rsync
  fi
  if [[ "$APP_INSTALL_GIT" == true ]]; then
    os_install_apps_git
  fi
  if [[ "$APP_INSTALL_FASTFETCH" == true ]]; then
    os_install_apps_fastfetch
  fi
  if [[ "$APP_INSTALL_NVM" == true ]]; then
    os_install_apps_nvm
  fi
  if [[ "$APP_INSTALL_PM2" == true ]]; then
    os_install_apps_pm2
  fi
  if [[ "$APP_INSTALL_DOCKER" == true ]]; then
    os_install_apps_docker
  fi
  if [[ "$APP_INSTALL_AWS_CLI" == true ]]; then
    os_install_apps_aws_cli
  fi
  
  success "Aplicativos instalados com sucesso."
}

# 
# Configure SSH
# 
configure_ssh() {
  info "Validating SSH environment variables..."
  require_env SSH_PORT
  require_env SSH_USER

  info "Validating environment variables..."
  ssh_validate_port "$SSH_PORT"
  ssh_validate_user "$SSH_USER"
  
  ssh_configure
}

create_ssh_user() {
  info "Validating SSH user creation environment variables..."
  require_env SSH_CREATE_USER_EMAIL

  ssh_create_user
}

# 
# Configure VPN
# 
configure_vpn() {
  info "Validating VPN environment variables..."
  require_env VPN_CONFIGURE_PORT
  require_env VPN_CONFIGURE_USER
  require_env VPN_CONFIGURE_ENABLE_IP_FORWARDING
  require_env VPN_CONFIGURE_PRIVATE_KEY_NAME
  require_env VPN_CONFIGURE_PUBLIC_KEY_NAME
  require_env VPN_CONFIGURE_IPV4_OCTET_1
  require_env VPN_CONFIGURE_IPV4_OCTET_2
  require_env VPN_CONFIGURE_IPV4_OCTET_3
  require_env VPN_CONFIGURE_IPV4_OCTET_4
  require_env VPN_CONFIGURE_IPV4_SUBNET
  require_env VPN_CONFIGURE_SERVER_NETWORK
  require_env VPN_CONFIGURE_SERVER_IP

  vpn_configure
}

create_vpn_user() {
  info "Validating VPN user creation environment variables..."
  require_env VPN_CREATE_USER_EMAIL
  require_env VPN_CREATE_USER_FIRST_VALID_CLIENT_IP

  vpn_create_user
}

#
# Instalar e Configurar UFW (Firewall)
#
configure_firewall() {
  firewall_configure
}

#
# Instalar e Configurar Fail2Ban
#
condigure_fail2ban() {
  fail2ban_configure
}

#
# Configurar Acesso GitHub Actions
#


init "$@"
