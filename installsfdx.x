#!/bin/bash

log() {
  local message="$1"
  local type="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local color
  local endcolor="\033[0m"

  case "$type" in
    "info") color="\033[38;5;79m" ;;
    "success") color="\033[1;32m" ;;
    "error") color="\033[1;31m" ;;
    *) color="\033[1;34m" ;;
  esac

  echo -e "${color}${timestamp} - ${message}${endcolor}"
}

handle_error() {
  local exit_code=$1
  local error_message="$2"
  log "Error: $error_message (Exit Code: $exit_code)" "error"
  exit $exit_code
}

check_os() {
    if ! [ -f "/etc/debian_version" ]; then
        echo "Error: This script is only supported on Debian-based systems."
        exit 1
    fi
}

install_pre_reqs() {
  log "Installing pre-requisites" "info"

  # Install node source
  if ! curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION%%.**}.x | sudo bash -; then
    handle_error "$?" "Failed to install node source"
  fi

  # Run 'apt-get update'
  if ! sudo apt-get update -y; then
    handle_error "$?" "Failed to run 'apt-get update'"
  fi

  # Run 'apt-get install'
  if ! sudo apt-get install -y default-jdk nodejs=${NODE_VERSION}-1nodesource1; then
    handle_error "$?" "Failed to install packages"
  fi

  # Cleanup apt cache
  if ! sudo rm -rf /var/lib/apt/lists/*; then
    handle_error "$?" "Failed to cleanup apt cache"
  fi
}

install_sf_cli() {
  log "Installing Salesforce CLI" "info"

  # Create CLI path
  if ! mkdir -p $HOME/cli/sf; then
    handle_error "$?" "Failed to create cli path"
  fi

  # Download and install Salesforce CLI
  if ! curl -fsSL https://developer.salesforce.com/media/salesforce-cli/sf/channels/${SF_CHANNEL}/sf-linux-${ARCH}.tar.gz | tar zxvf - -C $HOME/cli/sf --strip-components 1 ; then
    handle_error "$?" "Failed to install Salesforce CLI"
  fi
}

ARCH=$(dpkg --print-architecture)
NODE_VERSION=20.11.1
SF_CHANNEL=stable

if ! [ -f "/.sfcli" ]; then
  # Check OS
  check_os

  # Main execution
  install_pre_reqs || handle_error $? "Failed installing pre-requisites"
  install_sf_cli || handle_error $? "Failed installing Salesforce CLI"
  sudo touch /.sfcli
fi

PATH="$PATH:$HOME/cli/sf/bin"
