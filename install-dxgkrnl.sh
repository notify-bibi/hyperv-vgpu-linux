#!/bin/bash

sudo pacman -Sy --needed mesa mesa-utils mesa-d3d12 mesa-utils xorg-xwayland gputest

if modinfo dxgkrnl; then
  echo "dxgkrnl exists, skip install"
  return
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