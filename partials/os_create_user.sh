#!/usr/bin/env bash

os_create_user_new() {
  adduser --disabled-password --gecos "" "$1"
  echo "$1:$2" | chpasswd
}

os_create_user_add_to_group() {
  usermod -aG "$2" "$1"
}

os_create_user_change_user() {
  exec su - "$1"
}
