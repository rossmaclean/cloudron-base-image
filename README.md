Building
--------
* docker build -t girish/base . # builds as girish/base:latest
* ./flatten.sh girish/base 0.2 # specify the latest tag here
* docker push girish/base:<tag>

WARNING: Don't do `docker push girish/base` since this will
push the latest tag as well.

Links
-----
* https://blogs.oracle.com/jsmyth/entry/apparmor_and_mysql

Notes
-----
Every RUN command creates a new AUFS layer. AUFS itself has a limit
for 127 layers total.
    https://github.com/docker/docker/issues/332

