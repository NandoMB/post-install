#!/usr/bin/env bash

os_install_apps_rsync() {
  info "Instalando RSync..."
  sudo apt install -y rsync
}

os_install_apps_git() {
  info "Instalando Git..."
  sudo apt install -y git
}

os_install_apps_fastfetch() {
  info "Instalando FastFetch..."
  sudo apt install -y fastfetch
}

os_install_apps_nvm() {
  info "Instalando NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$ACTIVE_USER_HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  nvm install --lts --default
}

os_install_apps_pm2() {
  info "Instalando PM2..."
  npm install pm2@latest -g
  pm2 startup
}

os_install_apps_docker() {
  info "Instalando Docker..."
  sudo apt install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $ACTIVE_USER
  newgrp docker
  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service
}

os_install_apps_aws_cli() {
  info "Instalando AWS CLI..."
  sudo apt install -y awscli jq pv gzip
}