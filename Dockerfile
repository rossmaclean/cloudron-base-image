# https://github.com/docker-library/repo-info/blob/master/repos/ubuntu/remote/bionic-20180821.md
FROM ubuntu:bionic-20180821@sha256:de774a3145f7ca4f0bd144c7d4ffb2931e06634f11529653b23eba85aef8e378

ENV DEBIAN_FRONTEND noninteractive
# Do not cache apt packages
# https://wiki.ubuntu.com/ReducingDiskFootprint
RUN echo 'Acquire::http {No-Cache=True;};' > /etc/apt/apt.conf.d/no-cache && \
    echo 'APT::Install-Recommends "0"; APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend && \
    echo 'Dir::Cache { srcpkgcache ""; pkgcache ""; }' > /etc/apt/apt.conf.d/02nocache && \
    echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/02compress-indexes

RUN apt-get -y update && \
    # Software installation
    apt-get -y install ca-certificates curl git wget unzip zip software-properties-common build-essential \
    # Process managers
    supervisor \
    # install sendmail
    postfix \
    # install net packages useful for debugging
    iputils-ping telnet netcat lsof net-tools openssl dnsutils rsync bind9-host \
    # config file manipulation
    crudini xmlstarlet \
    # General purpose
    pwgen swaks vim nano cmake pkg-config openssh-client uuid sudo less zip \
    # apache
    apache2 libapache2-mod-php7.2 libapache2-mod-perl2 \
    # nginx
    nginx-full \
    # Databases (clients)
    sqlite3 mysql-client redis-tools postgresql-client ldap-utils mongodb-clients \
    # Dev packages (useful for native modules in ruby, node)
    gettext imagemagick libcurl4 libcurl4-openssl-dev libexpat1-dev libffi-dev libgdbm-dev libicu-dev libmysqlclient-dev \
        libncurses5-dev libpq-dev libre2-dev libreadline-dev libxml2-dev libxslt-dev libyaml-dev zlib1g-dev \
    # perl
    perl \
    # ruby (note that gem is now called gem2.1 and gem2.2)
    ruby2.5-dev \
    # Python
    python2.7 gunicorn uwsgi-plugin-python python-dev python-pip python-setuptools virtualenv \
    # php
    php-apcu php-geoip php-imagick php-redis php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-gmp php7.2-json \
        php7.2-imap php7.2-intl php7.2-ldap php7.2-mbstring php7.2-mysqlnd php-pear php7.2-pgsql \
        php7.2-soap php7.2-sqlite php7.2-xml php7.2-xmlrpc php7.2-zip phpmyadmin composer && \
    # Delete apt-cache and let people apt-update on start. Without this, we keep getting apt-get errors for --fix-missing
    rm -rf /var/cache/apt /var/lib/apt/lists

# gosu
RUN curl -L https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 -o /usr/local/bin/gosu && chmod +x /usr/local/bin/gosu

## the installations are kept separate since these change a lot compared to above
# node
RUN mkdir -p /usr/local/node-8.12.0 && \
    curl -L https://nodejs.org/download/release/v8.12.0/node-v8.12.0-linux-x64.tar.gz  | tar zxf - --strip-components 1 -C /usr/local/node-8.12.0

# Go
ENV GOROOT /usr/local/go-1.11.1
RUN mkdir -p /usr/local/go-1.11.1 && \
    curl -L https://storage.googleapis.com/golang/go1.11.1.linux-amd64.tar.gz | tar zxf - -C /usr/local/go-1.11.1 --strip-components 1

# Put node, go in the path by default
ENV PATH /usr/local/node-8.12.0/bin:$GOROOT/bin:$PATH

# add a non-previleged user that apps can use
# by default, account is created as inactive which prevents login via openssh
# https://github.com/gitlabhq/gitlabhq/issues/5304
RUN adduser --uid 1000 --disabled-login --gecos 'Cloudron' cloudron && \
    passwd -d cloudron

