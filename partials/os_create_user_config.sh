#!/usr/bin/env bash

os_create_user_config_validate() {
  local USER_CONFIG_TEMPLATE_PATH="$1"

  if [[ ! -d "$USER_CONFIG_FILE_PATH" ]]; then
    error "Invalid file path: $USER_CONFIG_FILE_PATH"
    exit 1
  fi

  if [[ -z "$USER_CONFIG_FILE_NAME" ]]; then
    error "Invalid file name: $USER_CONFIG_FILE_NAME"
    exit 1
  fi

  if [[ ! -f "$USER_CONFIG_TEMPLATE_PATH" ]]; then
    error "Template não encontrado: $USER_CONFIG_TEMPLATE_PATH"
    exit 1
  fi
}

os_create_user_config_build_file() {
  local CONFIG_FILE="$1"
  local TEMPLATE_PATH="$2"

  touch "$CONFIG_FILE"
  export HEADER_BLOCK="$(os_create_user_config_generate_header_block "$SERVER_NAME")"
  envsubst '${HEADER_BLOCK}' < "$TEMPLATE_PATH" > "$CONFIG_FILE"

  chmod 600 "$CONFIG_FILE"
}

os_create_user_config_generate_header_block() {
  local TITLE=" $1 "
  local LINE_LENGTH=59
  local TOP_BOTTOM_LINE=$(printf '%*s' "$LINE_LENGTH" '' | tr ' ' '-')
  local STARS_TOTAL=$((LINE_LENGTH - ${#TITLE}))
  local STARS_LEFT=$(((STARS_TOTAL + 1) / 2))
  local STARS_RIGHT=$((STARS_TOTAL - STARS_LEFT))
  local MIDDLE_LINE="$(printf '%*s' "$STARS_LEFT" '' | tr ' ' '*')${TITLE}$(printf '%*s' "$STARS_RIGHT" '' | tr ' ' '*')"
  echo 'echo'
  echo "echo \"$TOP_BOTTOM_LINE\""
  echo "echo \"$MIDDLE_LINE\""
  echo "echo \"$TOP_BOTTOM_LINE\""
  echo 'echo'
}

os_create_user_config_add_to_bashrc() {
  local BASHRC_PATH="$(eval echo "~${SUDO_USER:-$USER}")/.bashrc"
  
  if [[ "$USER_CONFIG_ADD_TO_BASHRC" == true ]]; then
    if ! grep -Fxq "source $1" "$BASHRC_PATH"; then
      echo -e "\nsource $1" >> "$BASHRC_PATH"
      success "Arquivo adicionado ao $BASHRC_PATH"
    else
      warn "O arquivo $1 já existe em $BASHRC_PATH"
    fi
  fi

  source "$BASHRC_PATH"
}
