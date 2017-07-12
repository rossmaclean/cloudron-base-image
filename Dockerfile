FROM ubuntu:16.04
MAINTAINER Girish Ramakrishnan <girish@cloudron.io>

ENV DEBIAN_FRONTEND noninteractive
# Do not cache apt packages
# https://wiki.ubuntu.com/ReducingDiskFootprint
RUN echo 'Acquire::http {No-Cache=True;};' > /etc/apt/apt.conf.d/no-cache
RUN echo 'APT::Install-Recommends "0"; APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend
RUN echo 'Dir::Cache { srcpkgcache ""; pkgcache ""; }' > /etc/apt/apt.conf.d/02nocache
RUN echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/02compress-indexes

RUN apt-get -y update # sync up package information

# Software installation
RUN apt-get -y install ca-certificates curl git wget unzip

# Process managers
RUN apt-get -y install supervisor

# General purpose
RUN apt-get -y install build-essential pwgen swaks vim cmake pkg-config openssh-client uuid sudo less

# Dev packages (useful for native modules in ruby, node)
RUN apt-get -y install \
    gettext \
    imagemagick \
    libcurl3 \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libffi-dev \
    libgdbm-dev \
    libicu-dev \
    libmysqlclient-dev \
    libncurses5-dev \
    libreadline-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    zlib1g-dev

# Databases (clients)
RUN apt-get -y install sqlite3 mysql-client-5.7 redis-tools postgresql-client-9.5 ldap-utils mongodb-clients

# apache
RUN apt-get -y install apache2 libapache2-mod-php7.0 libapache2-mod-perl2

# nginx
RUN apt-get -y install nginx-full

# php
RUN apt-get -y install \
    php-apcu \
    php7.0-cli \
    php7.0-curl \
    php7.0-fpm \
    php7.0-gd \
    php7.0-gmp \
    php7.0-json \
    php7.0-intl \
    php7.0-ldap \
    php7.0-mcrypt \
    php7.0-mysqlnd \
    php7.0-pgsql \
    php7.0-sqlite \
    php7.0-xml \
    php7.0-xmlrpc \
    php7.0-zip \
    phpmyadmin

RUN curl -L https://getcomposer.org/download/1.3.2/composer.phar > /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# perl
RUN apt-get -y install perl

# ruby (note that gem is now called gem2.1 and gem2.2)
RUN apt-get -y install ruby2.3-dev

# Python
RUN apt-get install -y python2.7 gunicorn uwsgi-plugin-python

# java (maybe only runtime should be installed and not the JDK)
RUN apt-get install -y openjdk-8-jdk maven

# install sendmail
RUN apt-get install -y postfix

# install net packages useful for debugging
RUN apt-get install -y iputils-ping telnet netcat lsof net-tools openssl dnsutils rsync

# add a non-previleged user that apps can use
RUN adduser --disabled-login --gecos 'Cloudron' cloudron
# by default, account is created as inactive which prevents login via openssh
# https://github.com/gitlabhq/gitlabhq/issues/5304
RUN passwd -d cloudron

# ini config file manipulation
RUN apt-get install -y crudini

# xml config file manipulation
RUN apt-get install -y xmlstarlet

RUN apt-get install -y software-properties-common python-software-properties

# node (0.10.48)
RUN mkdir -p /usr/local/node-0.10.48
RUN curl -L  https://nodejs.org/dist/v0.10.48/node-v0.10.48-linux-x64.tar.gz | tar zxf - --strip-components 1 -C /usr/local/node-0.10.48

# node (0.12.18)
RUN mkdir -p /usr/local/node-0.12.18
RUN curl -L https://nodejs.org/dist/v0.12.18/node-v0.12.18-linux-x64.tar.gz | tar zxf - --strip-components 1 -C /usr/local/node-0.12.18

# node (4.7.3)
RUN mkdir -p /usr/local/node-4.7.3
RUN curl -L https://nodejs.org/download/release/v4.7.3/node-v4.7.3-linux-x64.tar.gz  | tar zxf - --strip-components 1 -C /usr/local/node-4.7.3

# node (6.9.5)
RUN mkdir -p /usr/local/node-6.9.5
RUN curl -L https://nodejs.org/download/release/v6.9.5/node-v6.9.5-linux-x64.tar.gz  | tar zxf - --strip-components 1 -C /usr/local/node-6.9.5

# go
RUN mkdir -p /usr/local/go-1.6.4
RUN curl -L https://storage.googleapis.com/golang/go1.6.4.linux-amd64.tar.gz | tar zxvf - -C /usr/local/go-1.6.4 --strip-components 1

RUN mkdir -p /usr/local/go-1.7.5
RUN curl -L https://storage.googleapis.com/golang/go1.7.5.linux-amd64.tar.gz | tar zxvf - -C /usr/local/go-1.7.5 --strip-components 1

# gosu
RUN curl -L https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 -o /usr/local/bin/gosu
RUN chmod +x /usr/local/bin/gosu

# Delete apt-cache and let people apt-update on start. Without this, we keep getting apt-get errors for --fix-missing
RUN rm -r /var/cache/apt /var/lib/apt/lists

