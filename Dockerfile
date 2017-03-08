FROM ubuntu:17.04

RUN apt-get update && apt-get install -y \
  rsync \
  wget \
  qemu-user-static \
  qemu-utils \
  parted

ENV WORKSPACE /workspace

ENTRYPOINT ["/workspace/scripts/create_image.sh"]
