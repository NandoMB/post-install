#!/usr/bin/env bash

os_auto_update_and_upgrade_packages() {
  sudo apt update && sudo apt upgrade -y
}

os_auto_update_configure_unattended_upgrades() {
  sudo apt install -y unattended-upgrades
  sudo dpkg-reconfigure --priority=low unattended-upgrades
}
