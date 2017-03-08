#!/bin/bash

set -e

# local directory
WORKSPACE=/workspace
ROMS=$WORKSPACE/roms
BIOS=$WORKSPACE/BIOS
DIR=`dirname $0`

# mounted directory
MOUNTED_WORKSPACE=/workspace/mount/home/pi/RetroPie
MOUNTED_ROMS=$MOUNTED_WORKSPACE/roms
MOUNTED_BIOS=$MOUNTED_WORKSPACE/BIOS

# source utils script
source $DIR/utils.sh

# set environment variables
VERSION_MAJOR="$RETROPIEVERSION"
IMAGE_SIZE_IN_GB="$IMAGE_SIZE_IN_GB"
BASE_IMAGE_SIZE=4


# if IMAGE_SIZE_IN_GB is not set then set size to be size of image + roms + bios
if [ -z $IMAGE_SIZE_IN_GB ]; then
    TOTAL_FOLDER_BYTES=$(du --total -s -B1 ${ROMS} ${BIOS} | tail -1 | awk '{ print $1; }')
    TOTAL_FOLDER_GIGABYTES=$(echo $TOTAL_FOLDER_BYTES | awk '{ byte =$1 /1024/1024^2 ; printf "%.0f", byte }')
    IMAGE_SIZE_IN_GB=$((${TOTAL_FOLDER_GIGABYTES} + ${BASE_IMAGE_SIZE}))
fi

log "1. Making a ${IMAGE_SIZE_IN_GB}GB image using RetroPie $VERSION_MAJOR"

# download
log "2. Downloading RetroPie Image $VERSION_MAJOR"
IMAGE_ARCHIVE_ABS=(`$DIR/image_tools.sh download $VERSION_MAJOR`)

# extract
log "3. Extracting RetroPie Image $IMAGE_ARCHIVE_ABS"
IMAGE_ABS=(`$DIR/image_tools.sh extract $VERSION_MAJOR`)

# grow image
log "4. Grow image $IMAGE_ABS"
sh $DIR/image_grow.sh $IMAGE_ABS $IMAGE_SIZE_IN_GB

# mount image
log "5. Mount image $IMAGE_ABS"
$DIR/image_tools.sh mount $IMAGE_ABS

# move files
log "6. Copying BIOS and roms files"
rsync -av --info=progress2 $BIOS/ $MOUNTED_BIOS/
rsync -av --info=progress2 $ROMS/ $MOUNTED_ROMS/

# unmount image
log "7. Unmounting image $IMAGE_ABS"
$DIR/image_tools.sh umount $IMAGE_ABS
