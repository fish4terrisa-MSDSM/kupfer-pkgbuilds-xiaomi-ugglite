#!/usr/bin/ash

run_hook() {
  # rootfsdetect must be run first, or otherwise a root variable must be defined in the boot cmdline
  if [ ! -n $root ]; then
    echo "root variable undefined. Aborting..."
    return 1
  fi

  # Sets $LOOPDEV and $SUBPARTNUMBER
  get_loopdev_partinfo $root

  # Check if root is inside of a nested partition table and fall over to resizing fs if not
  if [ -n $LOOPDEV ] && [ -n $SUBPARTNUMBER ] ; then
    if parted -s "$LOOPDEV" print free | tail -n2 | head -n1 | grep -qi "free space"; then
      echo "Found unallocated space on a subpartition. Resizing..."
      parted -s "$LOOPDEV" resizepart "$SUBPARTNUMBER" 100%
      partprobe
    fi
  fi

  unset LOOPDEV
  unset SUBPARTNUMBER

  e2fsck -fy "$root"
  # There is no need to check if filesystem needs to be resized since resize2fs already checks unless "-f" is specified
  resize2fs "$root"
}
