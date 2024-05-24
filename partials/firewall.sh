#!/usr/bin/env bash

firewall_configure() {
  info "Instalando UFW (Uncomplicated Firewall)..."
  sudo apt install ufw -y

  firewall_apply_rules

  info "Lembre-se de verificar as regras do firewall e ajustar conforme necessário."
  success "Configuração do Firewall concluída."
}

firewall_apply_rules() {
  info "Configurando UFW..."

  local template="./templates/firewall_rules.tpl"
  local temp_file=$(mktemp)

  sed \
    -e "s|{{WG_PORT}}|$VPN_CONFIGURE_PORT|g" \
    -e "s|{{WG_INTERFACE}}|$VPN_CONFIGURE_INTERFACE|g" \
    -e "s|{{WG_SUBNET}}|$VPN_CONFIGURE_SERVER_NETWORK|g" \
    -e "s|{{SSH_PORT}}|$SSH_PORT|g" \
    "$template" > "$temp_file"

  info "Aplicando regras do firewall..."

  sudo ufw --force reset

  while IFS= read -r rule || [[ -n "$rule" ]]; do
    # Ignora linhas vazias e comentários
    [[ -z "$rule" || "$rule" =~ ^[[:space:]]*# ]] && continue
    
    # Garante que só comandos ufw serão executados
    [[ "$rule" =~ ^ufw[[:space:]] ]] || continue

    echo "Aplicando regra: $rule"
    sudo $rule
  done < "$temp_file"

  sudo ufw --force enable

  sudo ufw status numbered verbose
    
  sudo systemctl restart ufw

  rm "$temp_file"

  success "Configuração do Firewall concluída."
}
