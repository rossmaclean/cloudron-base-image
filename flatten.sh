#!/bin/bash

set -e
# set -v

if [ "$#" -ne 2 ]; then
    echo "Usage: flatten.sh <image_id> <tag>"
    exit 1
fi

IN_IMAGE="$1:latest"
OUT_IMAGE="$1:$2"
echo "Flattening $IN_IMAGE and tagging it as $OUT_IMAGE"

CONTAINER_ID=`docker run -d $IN_IMAGE /bin/true`
# flattemp is workaround for https://github.com/docker/docker/pull/7716
docker export $CONTAINER_ID | docker import - cloudron/flattemp > /dev/null
docker tag -f cloudron/flattemp $OUT_IMAGE
docker rmi cloudron/flattemp 2>&1 >/dev/null

echo "Done!"

