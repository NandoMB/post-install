#
# ATTENTION: UNCOMMENT THE LINES BELOW TO ENABLE CUSTOM USER CONFIGURATION AS NEEDED
#

######################################################################
#                      Environment Variables                         #
######################################################################
# export TERM=xterm-256color
# export EDITOR="nano"
# export NODE_ENV=production

#
# NVM (Node Version Manager)
#
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

######################################################################
#                             Configs                                #
######################################################################
${HEADER_BLOCK}
# neofetch
# echo
# pm2 list
# echo

######################################################################
#                              Aliases                               #
######################################################################
# General
# alias config-source="source $USER_CONFIG_FILE_PATH/$USER_CONFIG_FILE_NAME"
# alias config-open="nano $USER_CONFIG_FILE_PATH/$USER_CONFIG_FILE_NAME"
# alias myip="printf \"Local: %s\nPublic: %s\n\" \"$(hostname -I | awk '{print $1}')\" \"$(curl -s https://api.ipify.org)\""

# Docker
# alias docker-ports="sudo lsof -i -P -n | grep \$1"
# alias docker-ps="docker ps -a --format '\''table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.RunningFor}}'\''"

# Fail2Ban
# alias fail2ban-status="sudo fail2ban-client status sshd"
# alias fail2ban-log="sudo cat /var/log/fail2ban.log | grep '\[sshd\]' --color"

# UFW
# alias ufw-block-ls="sudo journalctl -f | grep 'UFW BLOCK'"

# PM2
# alias pm2-reload="pm2 reload ~/apps/ecosystem.config.js || pm2 start ~/apps/ecosystem.config.js"
# alias pm2-reload-envs="pm2 reload ~/apps/ecosystem.config.js --update-env || pm2 start ~/apps/ecosystem.config.js --update-env"
# alias pm2-flush-logs="pm2 flush all"
# alias pm2-reset-statistics="pm2 reset all"

######################################################################
#                              Others                                #
######################################################################
prompt() { printf "\033[1;36m[USER]\033[0m  %s"   "$1"; }
info() { printf "\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
success() { printf "\033[1;32m[DONE]\033[0m  %s\n" "$1"; }
warn() { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }
error() { printf "\033[1;31m[FAIL]\033[0m  %s\n" "$1"; }
overwrite() {
  local file="$1"

  if [[ -z "$file" ]]; then
    error "Você deve informar o nome do arquivo."
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    error "Arquivo '$file' não existe."
    return 1
  fi

  warn "O arquivo '$file' será apagado permanentemente."
  read -rp "[USER] Deseja realmente sobrescrever? (y/N): " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    truncate -s 0 "$file" && nano "$file"
  else
    info "Operação cancelada."
    return 1
  fi
}
