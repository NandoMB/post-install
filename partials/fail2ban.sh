#!/usr/bin/env bash

fail2ban_configure() {
  local template="./templates/fail2ban.tpl"
  
  info "Instalando Fail2Ban..."
  sudo apt install -y fail2ban

  info "Gerando $FAIL2BAN_JAIL_LOCAL com porta SSH: $SSH_PORT..."
  export SSH_PORT
  envsubst < "$template" | sudo tee "$FAIL2BAN_JAIL_LOCAL" > /dev/null
  
  info "Iniciando o serviço Fail2Ban..."
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban

  sudo fail2ban-client status sshd
  success "Fail2Ban instalado e configurado com sucesso."
}
