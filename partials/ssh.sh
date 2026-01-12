#!/usr/bin/env bash

SSH_CONFIG_FILE_NAME="sshd_config"
SSH_CONFIG_PATH="/etc/ssh"
SSH_CONFIG_FILE="$SSH_CONFIG_PATH/$SSH_CONFIG_FILE_NAME"

SSH_DIRECTORY="$ACTIVE_USER_HOME/.ssh"
SSH_KEYS_DIRECTORY="$SSH_DIRECTORY/keys"
SSH_AUTHORIZED_FILE="$SSH_DIRECTORY/authorized_keys"

SSH_KEY_NAME="${SSH_CREATE_USER_EMAIL//[^a-zA-Z0-9]/_}"
SSH_KEY_PATH="$SSH_KEYS_DIRECTORY/$SSH_KEY_NAME"

#
# Validate
#
ssh_validate_port() {
  local input="$1"
  if [[ "$input" =~ ^[1-9][0-9]*$ ]] && { (( input == 22 )) || (( input >= 1024 && input <= 65535 )); }; then
    return 0
  else
    error "Porta inválida. Abortando operação..."
    exit 1
  fi
}

ssh_validate_user() {
  local user="$1"
  if id "$user" &>/dev/null; then
    return 0
  else
    error "Usuário '$user' não foi encontrado. Abortando operação..."
    exit 1
  fi
}

#
# Configure
#
ssh_configure() {
  info "Configurando SSH..."
  ssh_backup_original_config_file
  ssh_create_config_file
  ssh_restart_service
  success "SSH configurado com sucesso."
}

ssh_backup_original_config_file() {
  info "Fazendo backup do arquivo $SSH_CONFIG_FILE em $SSH_CONFIG_FILE.bak"
  sudo cp "$SSH_CONFIG_FILE" "$SSH_CONFIG_FILE.bak"
}

ssh_create_config_file() {
  local TEMPLATE_FILE="./templates/ssh_configure.tpl"
  local TEMP_FILE="$(mktemp)"

  sed \
    -e "s|{{SSH_PORT}}|$SSH_PORT|g" \
    -e "s|{{SSH_USER}}|$SSH_USER|g" \
    "$TEMPLATE_FILE" > "$TEMP_FILE"

  sudo cp "$TEMP_FILE" "$SSH_CONFIG_FILE"
  rm "$TEMP_FILE"
}

ssh_restart_service() {
  info "Reiniciando o serviço SSH"
  sudo systemctl reload ssh || sudo systemctl restart ssh
}

#
# Create User
#
ssh_create_user() {
  ssh_create_user_create_files
  ssh_create_user_generate_keys
  ssh_create_user_authorize_keys
}

ssh_create_user_create_files() {
  info "Criando diretórios e arquivos..."
  mkdir -p "$SSH_KEYS_DIRECTORY"
  touch "$SSH_AUTHORIZED_FILE"

  info "Alterando permissões..."
  chmod -R 700 "$SSH_KEYS_DIRECTORY"
  chmod 600 "$SSH_AUTHORIZED_FILE"
}

ssh_create_user_generate_keys() {
  info "Gerando chaves SSH."
  ssh-keygen -t ed25519 -C "$SSH_CREATE_USER_EMAIL" -N "" -f "$SSH_KEY_PATH"

  success "Chave SSH gerada: $SSH_KEY_PATH"
  echo
  echo "🔑 Chave pública:"
  echo "Incluída em $SSH_AUTHORIZED_FILE"
  echo
  echo "🔐 Chave privada (guarde com segurança!):"
  cat "$SSH_KEY_PATH"
  echo
  info "Envie a chave privada ao usuário $SSH_CREATE_USER_EMAIL."
  info "Excluindo a chave privada do sistema por segurança."
  rm -f "$SSH_KEY_PATH"
  success "Chave privada excluída do sistema."
}

ssh_create_user_authorize_keys() {
  if grep -q -F -f "$SSH_KEY_PATH.pub" "$SSH_AUTHORIZED_FILE"; then
    info "A chave já existe no arquivo authorized_keys. Nenhuma alteração feita."
  else
    cat "$SSH_KEY_PATH.pub" >> "$SSH_AUTHORIZED_FILE"
    success "Chave pública adicionada ao arquivo $SSH_AUTHORIZED_FILE"
  fi
}
