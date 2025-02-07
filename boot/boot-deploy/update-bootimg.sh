#!/bin/bash
set -e

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

if [ ! -f /etc/kupfer/deviceinfo ]; then
  echo "No deviceinfo found at /etc/kupfer/deviceinfo. This might be intentional"
  exit 1
fi

eval "$(cat /etc/kupfer/deviceinfo)"

unset initramfs_file
if [ -f "/boot/initramfs-initsquared.img" ]; then
  initramfs_file="initramfs-initsquared.img"
elif [ -f "/boot/initramfs-linux.img" ]; then
  initramfs_file="initramfs-linux.img"
elif [ -z "$1" ]; then
  echo "/boot/initramfs-initsquared.img or /boot/initramfs-linux.img not found. initramfs location must be specified via argument."
  exit 1
else
  initramfs_file="$1"
fi

echo "Generating and flashing new aboot.img with initramfs $initramfs_file"

# Clean up old aboot.img and boot.img (in case of error) before running boot-deploy to save on disk space in /boot
if [ -f /boot/aboot.img ]; then
  rm /boot/aboot.img
fi

if [ -f /boot/boot.img ]; then
  rm /boot/boot.img
fi

boot-deploy -i "$initramfs_file" -k Image.gz -d /boot -o /boot -c /etc/kupfer/deviceinfo
mv /boot/boot.img /boot/aboot.img
