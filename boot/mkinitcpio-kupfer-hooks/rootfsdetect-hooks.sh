#!/usr/bin/ash

run_hook() {
  source /usr/lib/initcpio/hooks/kupfer-functions.sh

  # Some bootloaders mess with those options (e.g. OnePlus 6), therefore we need to overwrite them
  # This is not nice, but there is no other way (at least right now)
  export rwopt=rw
  export init=/sbin/init

  eval "$(cat /etc/kupfer/deviceinfo)"
  deviceinfo_partitions_microsd="$deviceinfo_partitions_microsd"
  deviceinfo_partitions_data="$deviceinfo_partitions_data"

  if [ -n "$kupfer_root_uuid" ]; then
    query="UUID=${kupfer_root_uuid}"
  else
    query="LABEL=kupfer_root"
  fi

  if [ $root = "/dev/mapper/cryptroot" ]; then
    echo "rootfsdetect found root=/dev/mapper/cryptroot. Skipping..."
    return 0
  fi

  for _root in "$root" "$deviceinfo_partitions_microsd" "$deviceinfo_partitions_data" "/dev/disk/by-label/kupfer_root"; do
    if [ -e "$_root" ] && scan_partitions "$_root" "$query"; then
      echo "Found kupfer_root at: $RESULT"
      export root="$RESULT"
      return 0
    fi
  done

  # Fall back to scanning for partitions

  echo -n "${query} not found as a raw partition"
  [ -z "$deviceinfo_partitions_microsd" ] || echo -n " nor in data partition '$deviceinfo_partitions_microsd'"
  [ -z "$deviceinfo_partitions_data" ] || echo -n " nor in data partition '$deviceinfo_partitions_data'"
  echo -e ".\nScanning more partitions..."

  unset RESULT

  for part in /dev/sd?[0-9]* /dev/mmcblk[0-9]p* /dev/nvme[0-9]n[0-9]p* /dev/vd?[0-9]* /dev/hd?[0-9]* ; do
    ! scan_partitions "$part" "$query" || break
  done

  if [ -n "$RESULT" ]; then
    echo "Found rootfs ${query} at: $RESULT (bruteforce)"
    export root="$RESULT"
  else
    echo "Failed to find a partition ${query}."
    unset root
  fi

  unset SUBPARTNUMBER
  unset LOOPDEV
}
