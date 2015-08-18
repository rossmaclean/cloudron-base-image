FROM ubuntu:14.10
MAINTAINER Girish Ramakrishnan <girish@forwardbias.in>

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
RUN apt-get -y install build-essential pwgen swaks vim cmake pkg-config openssh-client

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

# Databases
RUN apt-get -y install sqlite3 mysql-client-5.6 redis-tools postgresql-client-9.4 ldap-utils

# node
RUN curl -sL https://deb.nodesource.com/setup_0.10 | bash -
RUN apt-get install -y nodejs
RUN update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10

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

# perl
RUN apt-get -y install perl

# ruby
RUN apt-get -y install ruby-dev
RUN gem install bundler --no-ri --no-rdoc

# Python
RUN apt-get install -y gunicorn uwsgi-plugin-python

# java (maybe only runtime should be installed and not the JDK)
RUN apt-get install -y openjdk-8-jdk maven

# go
RUN apt-get install -y golang

# add a non-previleged user that apps can use
RUN adduser --disabled-login --gecos 'Cloudron' cloudron
# by default, account is created as inactive which prevents login via openssh
# https://github.com/gitlabhq/gitlabhq/issues/5304
RUN passwd -d cloudron

# Delete apt-cache and let people apt-update on start. Without this, we keep getting apt-get errors for --fix-missing
RUN rm -r /var/cache/apt /var/lib/apt/lists

