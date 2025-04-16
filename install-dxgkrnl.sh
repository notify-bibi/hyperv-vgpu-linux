#!/bin/bash
set -e

sudo pacman -Sy --needed mesa mesa-utils xorg-xwayland

if modinfo dxgkrnl; then
  echo "dxgkrnl exists, skip install"
  exit 0
fi

git clone https://github.com/notify-bibi/dxgkrnl-dkms-git
cd dxgkrnl-dkms-git
makepkg -si OPTIONS=-debug
sudo modprobe dxgkrnl

if ! modinfo dxgkrnl; then
  echo "failed to install dxgkrnl"
  exit 1
fi

echo "Success"