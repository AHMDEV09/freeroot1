#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

# Detect CPU architecture
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# Installation steps
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                      Foxytoux INSTALLER"
  echo "#"
  echo "#                           Copyright (C) 2024, RecodeStudios.Cloud"
  echo "#"
  echo "#"
  echo "#######################################################################################"

  read -p "Do you want to install macOS-like development tools? (YES/no): " install_tools
fi

case $install_tools in
  [yY][eE][sS])
    # Install Homebrew (macOS-like package manager)
    if ! command -v brew &> /dev/null; then
      echo "Homebrew not found, installing..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo "Homebrew already installed."
    fi

    # Install additional macOS-like tools via Homebrew
    brew install wget zsh git
    ;;
  *)
    echo "Skipping macOS-like tool installation."
    ;;
esac

# Setup PRoot and related environment (for running a different root filesystem, if desired)
if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm $ROOTFS_DIR/usr/local/bin/proot -rf
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi

    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    sleep 1
  done

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# DNS resolution setup for rootfs
if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin
  touch $ROOTFS_DIR/.installed
fi

# Display success message
CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

clear
display_gg

# Running proot environment (if desired for additional emulation)
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
