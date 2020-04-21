# https://hub.docker.com/_/ubuntu/?tab=tags
FROM ubuntu:bionic-20200311@sha256:e5dd9dbb37df5b731a6688fa49f4003359f6f126958c9c928f937bec69836320

ENV DEBIAN_FRONTEND noninteractive
# Do not cache apt packages
# https://wiki.ubuntu.com/ReducingDiskFootprint
RUN echo 'Acquire::http {No-Cache=True;};' > /etc/apt/apt.conf.d/no-cache && \
    echo 'APT::Install-Recommends "0"; APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend && \
    echo 'Dir::Cache { srcpkgcache ""; pkgcache ""; }' > /etc/apt/apt.conf.d/02nocache && \
    echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/02compress-indexes

RUN apt-get -y update && \
    # Software installation
    apt-get -y install ca-certificates curl git wget unzip zip software-properties-common build-essential make gcc g++ \
    # Process managers
    supervisor \
    # install sendmail
    postfix \
    # install net packages useful for debugging
    iputils-ping telnet netcat lsof net-tools openssl dnsutils rsync bind9-host \
    # config file manipulation
    crudini xmlstarlet moreutils jq \
    # General purpose
    pwgen swaks vim nano emacs cmake pkg-config openssh-client openssh-server uuid sudo less zip dirmngr gpg gpg-agent file \
    # apache
    apache2 libapache2-mod-php7.2 libapache2-mod-perl2 \
    # nginx
    nginx-full \
    # Databases (clients)
    sqlite3 mysql-client redis-tools postgresql-client ldap-utils mongodb-clients \
    # Dev packages (useful for native modules in ruby, node)
    gettext imagemagick libcurl4 libcurl4-openssl-dev libexpat1-dev libffi-dev libgdbm-dev libicu-dev libmysqlclient-dev \
        libncurses5-dev libpq-dev libre2-dev libreadline-dev libssl-dev libxml2-dev libxslt-dev libyaml-dev zlib1g-dev \
        libmcrypt-dev libgmp-dev libfreetype6-dev libjpeg-dev libjpeg-turbo8-dev libpng-dev chrpath libxft-dev libfontconfig1-dev \
        libkrb5-dev libpq-dev libxslt1-dev libldap2-dev libsasl2-dev \
    # perl
    perl libimage-exiftool-perl \
    # ruby (note that gem is now called gem2.1 and gem2.2)
    ruby2.5-dev \
    # Python 2
    python2.7 gunicorn uwsgi-plugin-python python-dev python-pip python-setuptools virtualenv \
    # php 7.2
    php-apcu php-geoip php-imagick php-redis php7.2-bcmath php7.2-cli php7.2-ctype php7.2-curl php7.2-dom php7.2-fileinfo php7.2-fpm php7.2-gd php7.2-gettext php7.2-gmp php7.2-json php7.2-tidy \
        php7.2-iconv php7.2-imap php7.2-intl php7.2-ldap php7.2-mbstring php7.2-mysqlnd php7.2-phar php-pear php7.2-pgsql php7.2-redis \
        php7.2-simplexml php7.2-soap php7.2-sqlite php7.2-tokenizer php7.2-xml php7.2-xmlrpc php7.2-zip phpmyadmin composer && \
    # java
    openjdk-8-jdk-headless && \
    # Delete apt-cache and let people apt-update on start. Without this, we keep getting apt-get errors for --fix-missing
    rm -rf /var/cache/apt /var/lib/apt/lists

# gosu
RUN curl -L https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64 -o /usr/local/bin/gosu && chmod +x /usr/local/bin/gosu

## the installations are kept separate since these change a lot compared to above
# node (https://nodejs.org/en/download/)
ARG NODEVERSION=12.6.2
RUN mkdir -p /usr/local/node-${NODEVERSION} && \
    curl -L https://nodejs.org/download/release/v${NODEVERSION}/node-v${NODEVERSION}-linux-x64.tar.gz  | tar zxf - --strip-components 1 -C /usr/local/node-${NODEVERSION}

ARG NODEPREVVERSION=10.20.1
RUN mkdir -p /usr/local/node-${NODEPREVVERSION} && \
    curl -L https://nodejs.org/download/release/v${NODEPREVVERSION}/node-v${NODEPREVVERSION}-linux-x64.tar.gz  | tar zxf - --strip-components 1 -C /usr/local/node-${NODEPREVVERSION}

# Go (https://golang.org/dl/)
ARG GOVERSION=1.14.2
ENV GOROOT /usr/local/go-${GOVERSION}
RUN mkdir -p /usr/local/go-${GOVERSION} && \
    curl -L https://storage.googleapis.com/golang/go${GOVERSION}.linux-amd64.tar.gz | tar zxf - -C /usr/local/go-${GOVERSION} --strip-components 1

# Keep bash history around as long as /run is alive
RUN ln -sf /run/.bash_history /root/.bash_history && \
    ln -sf /run/.psql_history /root/.psql_history

# Put node, go in the path by default
ENV PATH /usr/local/node-${NODEVERSION}/bin:$GOROOT/bin:$PATH

# add a non-previleged user that apps can use
# by default, account is created as inactive which prevents login via openssh
# https://github.com/gitlabhq/gitlabhq/issues/5304
RUN adduser --uid 1000 --disabled-login --gecos 'Cloudron' cloudron && \
    passwd -d cloudron

