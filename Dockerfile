FROM ubuntu:14.10
MAINTAINER Girish Ramakrishnan <girish@cloudron.io>

ENV DEBIAN_FRONTEND noninteractive
# Do not cache apt packages
# https://wiki.ubuntu.com/ReducingDiskFootprint
RUN echo 'Acquire::http {No-Cache=True;};' > /etc/apt/apt.conf.d/no-cache
RUN echo 'APT::Install-Recommends "0"; APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend
RUN echo 'Dir::Cache { srcpkgcache ""; pkgcache ""; }' > /etc/apt/apt.conf.d/02nocache
RUN echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/02compress-indexes

RUN apt-get -y update # sync up package information
#
## needed for add-apt-repository
#RUN apt-get install -y software-properties-common
#

# Software installation
RUN apt-get -y install ca-certificates curl git wget unzip

# Process managers
RUN apt-get -y install supervisor

# General purpose
RUN apt-get -y install build-essential pwgen swaks vim cmake pkg-config openssh-client uuid

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
RUN apt-get -y install sqlite3 mysql-client-5.6 redis-tools postgresql-client-9.4 ldap-utils mongodb-clients

# node (0.10.40)
RUN mkdir -p /usr/local/node-0.10.40
RUN curl -L  https://nodejs.org/dist/v0.10.40/node-v0.10.40-linux-x64.tar.gz | tar zxf - --strip-components 1 -C /usr/local/node-0.10.40

# node (0.12.7)
RUN mkdir -p /usr/local/node-0.12.7
RUN curl -L https://nodejs.org/dist/v0.12.7/node-v0.12.7-linux-x64.tar.gz | tar zxf - --strip-components 1 -C /usr/local/node-0.12.7

# node (4.1.1)
RUN mkdir -p /usr/local/node-4.1.1
RUN curl -L https://nodejs.org/dist/v4.1.1/node-v4.1.1-linux-x64.tar.gz | tar zxf - --strip-components 1 -C /usr/local/node-4.1.1

# apache
RUN apt-get -y install apache2 libapache2-mod-php5 libapache2-mod-perl2

# nginx
RUN apt-get -y install nginx-full

# php
RUN apt-get -y install \
    php-apc \
    php5-cli \
    php5-curl \
    php5-fpm \
    php5-gd \
    php5-gmp \
    php5-json \
    php5-intl \
    php5-ldap \
    php5-mcrypt \
    php5-mysqlnd \
    php5-pgsql \
    php5-sqlite \
    phpmyadmin

RUN curl -sS https://getcomposer.org/installer | php -- --version=1.0.0-alpha10
RUN mv composer.phar /usr/local/bin/composer

# perl
RUN apt-get -y install perl

# ruby
RUN apt-get -y install ruby2.1-dev
RUN gem install bundler --no-ri --no-rdoc

# Python
RUN apt-get install -y python2.7 gunicorn uwsgi-plugin-python

# java (maybe only runtime should be installed and not the JDK)
RUN apt-get install -y openjdk-8-jdk maven

# go
RUN mkdir -p /usr/local/go-1.5.1
RUN curl -L https://storage.googleapis.com/golang/go1.5.1.linux-amd64.tar.gz | tar zxvf - -C /usr/local/go-1.5.1 --strip-components 1
ENV PATH /usr/local/go-1.5.1/bin:$PATH

# install sendmail
RUN apt-get install -y postfix

# add a non-previleged user that apps can use
RUN adduser --disabled-login --gecos 'Cloudron' cloudron
# by default, account is created as inactive which prevents login via openssh
# https://github.com/gitlabhq/gitlabhq/issues/5304
RUN passwd -d cloudron

# Delete apt-cache and let people apt-update on start. Without this, we keep getting apt-get errors for --fix-missing
RUN rm -r /var/cache/apt /var/lib/apt/lists

