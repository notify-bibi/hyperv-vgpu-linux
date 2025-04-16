#!/bin/bash
set -e

cat /proc/modules | grep dxgkrnl
lsmod | grep dxgkrnl

ls /dev/dxg -l

lspci -v

ls /dev/dri/card*

export LIBGL_ALWAYS_SOFTWARE=0 GALLIUM_DRIVER=d3d12


yay -Sy --needed gputest

gputest &

sleep 5

sudo cat /proc/`pgrep gputest`/maps | grep wsl

kill -9 `pgrep gputest`