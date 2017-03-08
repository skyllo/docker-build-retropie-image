#!/bin/bash

set -e

# local directory
WORKSPACE=/workspace
IMAGES=$WORKSPACE/images
MOUNT_DIR=$WORKSPACE/mount
DIR=`dirname $0`

# set image
VERSION_MAJOR=$2
IMAGE_NAME=retropie-${VERSION_MAJOR}-rpi2_rpi3.img
IMAGE_ABS=$IMAGES/$IMAGE_NAME
IMAGE_ARCHIVE_NAME=${IMAGE_NAME}.gz
IMAGE_ARCHIVE_ABS=$IMAGES/$IMAGE_ARCHIVE_NAME

# source utils script
source $DIR/utils.sh

img_download() {
  if [ ! -f $IMAGE_ARCHIVE_ABS ]; then
      wget https://github.com/RetroPie/RetroPie-Setup/releases/download/$VERSION_MAJOR/$IMAGE_ARCHIVE_NAME -O $IMAGE_ARCHIVE_ABS || rm -f $IMAGE_ARCHIVE_ABS
  fi
  echo $IMAGE_ARCHIVE_ABS
}

img_extract() {
  if [ ! -f $IMAGE_ABS ]; then
      gunzip -c $IMAGE_ARCHIVE_ABS > $IMAGE_ABS
  fi
  echo $IMAGE_ABS
}

img_mount() {
  if [ ! -d $MOUNT_DIR ]; then
    log "image_tools - Making directories $MOUNT_DIR"
    mkdir -p $MOUNT_DIR
  fi

  # set image absolute path
  local MOUNT_IMAGE_ABS=$1

  log "img_mount - Unmounting existing LOOPS"
  losetup -D

  local ROOT_OFFSET=`fdisk -u -l ${MOUNT_IMAGE_ABS} | grep ${MOUNT_IMAGE_ABS}2 | tail -n 1 | awk '{print $2}'`
  local BOOT_OFFSET=`fdisk -u -l ${MOUNT_IMAGE_ABS} | grep ${MOUNT_IMAGE_ABS}1 | tail -n 1 | awk '{print $3}'`

  local IMAGE_LOOP=$(losetup -v -f --show $MOUNT_IMAGE_ABS)
  local IMAGE_LOOP2=$(losetup -v -f --show $MOUNT_IMAGE_ABS)

  log "img_mount - Mounting the image partitions using LOOPS $IMAGE_LOOP $IMAGE_LOOP2"
  mount -o offset=$((512*${ROOT_OFFSET})) "$IMAGE_LOOP" $MOUNT_DIR
  mount -o offset=$((512*${BOOT_OFFSET})) "$IMAGE_LOOP2" $MOUNT_DIR/boot
  mount --rbind /dev $MOUNT_DIR/dev
  mount -t proc none $MOUNT_DIR/proc
  mount -o bind /sys $MOUNT_DIR/sys

  log "img_mount - Copying the qemu-arm-static binary"
  cp "$(which qemu-arm-static)" $MOUNT_DIR/usr/bin/

  # Fix chroot
  log "img_mount - Fixing 'chroot'"
  sed -i -e 's/^/#/' $MOUNT_DIR/etc/ld.so.preload

  # Fix network
  log "img_mount - Fixing network settings"
  cp /etc/resolv.conf "$MOUNT_DIR/etc/resolv.conf"
}

img_umount() {
  log "img_umount - Unmounting the image partitions"
  umount -l $MOUNT_DIR/proc/ $MOUNT_DIR/dev/ $MOUNT_DIR/sys/ $MOUNT_DIR/boot $MOUNT_DIR/
}

img_chroot() {
  log "img_chroot - Executing 'chroot'"
  chroot $MOUNT_DIR/
}

main() {
  local CMD="$1"
  shift || true

  case "$CMD" in
    # Global Commands
    "download")        img_download "$@" ;;
    "extract")         img_extract "$@" ;;
    "mount")           img_mount "$@" ;;
    "umount")          img_umount "$@" ;;
    "chroot")          img_chroot "$@" ;;
    *)                 echo "Usage: mount/umount/chroot/download/extract" ;;
  esac
}

main "$@"
