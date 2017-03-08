#!/bin/sh

set -x

# local directory
DIR=`dirname $0`

# source utils script
. $DIR/utils.sh

if [ $# -ne 2 ]; then
  printf "Usage: ./grow_image IMAGEFILE IMAGE_SIZE_IN_GB\n"
  printf "Example: ./grow_image retropie.img 25\n"
  exit 1
fi

# set variables
IMAGEFILE="$1"
IMAGE_SIZE_IN_GB="$2"

# Grow the image file
dd of="$IMAGEFILE" bs=1 seek=${IMAGE_SIZE_IN_GB}G count=0

log "Creating LOOP"
LOOP_DEV=$(losetup -f)

log "Mounting $IMAGEFILE to LOOP $LOOP_DEV"
losetup -v $LOOP_DEV "$IMAGEFILE"

# Partition resizing code http://github.com/asb/raspi-config
PART_START=$(parted "$IMAGEFILE" -ms unit s p | grep "^2" | cut -f 2 -d: | tr -d s)
log "Paritioning from sector: $PART_START"
if [ ! "$PART_START" ]; then
  printf "Failed to extract root partition offset\n"
  exit 1
fi

fdisk -c -u $LOOP_DEV <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

log "Deleting LOOP $LOOP_DEV"
losetup -d $LOOP_DEV

PART_START_BYTES=$((${PART_START%s}*512))
log "Mounting LOOP from offset $PART_START"
losetup --offset "$PART_START_BYTES" -v $LOOP_DEV "$IMAGEFILE"

log "Running e2fsck on $LOOP_DEV"
e2fsck -f $LOOP_DEV

log "Running resize2fs on $LOOP_DEV"
resize2fs -p $LOOP_DEV

log "Unmounting LOOP $LOOP_DEV"
losetup -d $LOOP_DEV

log "Success!"
