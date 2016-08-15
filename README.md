This is the base image used for all docker containers in the Cloudron.

## Building

    docker build -t cloudron/base:<tag> .

## Pushing

    docker push cloudron/base:<tag>

*WARNING*: Don't do `docker push cloudron/base` since this will
push the latest tag as well.

