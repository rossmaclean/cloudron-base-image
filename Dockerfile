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
    # Software installation (for add-apt-repository and apt-key)
    apt-get -y install ca-certificates curl dirmngr git gpg gpg-agent wget unzip zip software-properties-common build-essential make gcc g++ sudo && \
    add-apt-repository -y ppa:ondrej/php && \
    # yarn
    apt-key adv --fetch-keys http://dl.yarnpkg.com/debian/pubkey.gpg && \
    echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get -y install \
    # Process managers
    supervisor \
    # install sendmail
    postfix \
    # install net packages useful for debugging
    iputils-ping telnet netcat lsof net-tools openssl dnsutils rsync bind9-host \
    # config file manipulation
    crudini xmlstarlet moreutils jq \
    # General purpose
    pwgen swaks vim nano emacs cmake pkg-config openssh-client openssh-server uuid less zip file yarn \
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
        libkrb5-dev libpq-dev libxslt1-dev libldap2-dev libsasl2-dev libtool libzmq3-dev yarn \
    # perl
    perl libimage-exiftool-perl \
    # ruby (note that gem is now called gem2.1 and gem2.2)
    ruby2.5-dev \
    # Python 2
    python2.7 gunicorn uwsgi-plugin-python python-dev python-pip python-setuptools virtualenv virtualenvwrapper \
    # Python 3
    python3-dev python3-pip \
    # php 7.3
    php7.3 php7.3-common php7.3-cli php7.3-dev php7.3-apcu php7.3-imagick php7.3-geoip libapache2-mod-php7.3 php7.3-redis php7.3-apcu php7.3-bcmath php7.3-bz2 php7.3-curl php7.3-dba php7.3-enchant \
    php7.3-gd php7.3-geoip php7.3-gettext php7.3-imagick php7.3-imap php7.3-intl php7.3-json php7.3-ldap php7.3-mbstring php7.3-opcache \
    php7.3-mysql php7.3-pgsql php7.3-readline php7.3-soap php7.3-sqlite3 php7.3-tidy php7.3-uuid php7.3-xml php7.3-xmlrpc \
    php7.3-zip php7.3-fpm \
    # java
    openjdk-8-jdk-headless && \
    # disable 7.2 apache mod
    a2dismod php7.2 && \
    # keep this here, otherwise it installs php 7.2
    apt install -y composer && \
    # Delete apt-cache and let people apt-update on start. Without this, we keep getting apt-get errors for --fix-missing
    rm -rf /var/cache/apt /var/lib/apt/lists

# gosu
RUN curl -L https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64 -o /usr/local/bin/gosu && chmod +x /usr/local/bin/gosu

## the installations are kept separate since these change a lot compared to above
# node (https://nodejs.org/en/download/)
ARG NODEVERSION=12.16.2
RUN mkdir -p /usr/local/node-${NODEVERSION} && \
    curl -L https://nodejs.org/dist/v${NODEVERSION}/node-v${NODEVERSION}-linux-x64.tar.xz | tar Jxf - --strip-components 1 -C /usr/local/node-${NODEVERSION}

ARG NODEPREVVERSION=10.20.1
RUN mkdir -p /usr/local/node-${NODEPREVVERSION} && \
    curl -L https://nodejs.org/dist/v${NODEPREVVERSION}/node-v${NODEPREVVERSION}-linux-x64.tar.xz | tar Jxf - --strip-components 1 -C /usr/local/node-${NODEPREVVERSION}

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

RUN addgroup --gid 500 --system cloudron-volume

RUN echo "set noswapfile" >> /root/.vimrc && \
    echo "set noswapfile" >> /home/cloudron/.vimrc

