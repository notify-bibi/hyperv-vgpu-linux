#!/bin/bash
set -e

echo "Moving files and setting permissions..."
cp -rf /tmp/wsl/libwsl/* /tmp/wsl/lib || :
cp -rf /tmp/wsl/libwsl/.* /tmp/wsl/lib || :
rm -rf /tmp/wsl/libwsl || :

(
  sudo rm -rf /usr/lib/wsl && \
  sudo mv /tmp/wsl /usr/lib/wsl && \
  sudo chmod -R 555 /usr/lib/wsl/drivers/ && \
  sudo chmod -R 755 /usr/lib/wsl/lib/ && \
  sudo chown -R root:root /usr/lib/wsl && \
  sudo ln -s /usr/lib/wsl/lib/libd3d12core.so /usr/lib/wsl/lib/libD3D12Core.so && \
  sudo ln -s /usr/lib/wsl/lib/libnvoptix.so.1 /usr/lib/wsl/lib/libnvoptix_loader.so.1 && \
  sudo ln -sf /usr/lib/wsl/lib/libcuda.so /usr/lib/wsl/lib/libcuda.so.1 && \
  echo "Updating ldconfig..." && \
  sudo echo "/usr/lib/wsl/lib" | sudo tee /etc/ld.so.conf.d/ld.wsl.conf && \
  sudo ldconfig && \
  echo 'export PATH=$PATH:/usr/lib/wsl/lib' | sudo tee /etc/profile.d/wsl.sh && \
  sudo chmod +x /etc/profile.d/wsl.sh && \
  echo "done"
) || echo "failed to install" && exit 1




