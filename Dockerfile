# https://hub.docker.com/_/ubuntu/?tab=tags
FROM ubuntu:jammy-20221101@sha256:817cfe4672284dcbfee885b1a66094fd907630d610cab329114d036716be49ba

ENV DEBIAN_FRONTEND noninteractive
# Do not cache apt packages
# https://wiki.ubuntu.com/ReducingDiskFootprint
RUN echo 'Acquire::http {No-Cache=True;};' > /etc/apt/apt.conf.d/no-cache && \
    echo 'APT::Install-Recommends "0"; APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend && \
    echo 'Dir::Cache { srcpkgcache ""; pkgcache ""; }' > /etc/apt/apt.conf.d/02nocache && \
    echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/02compress-indexes

SHELL ["/bin/bash", "-c"]

RUN apt -y update && \
    # Software installation (for add-apt-repository and apt-key)
    apt -y install ca-certificates curl dirmngr git gpg gpg-agent wget unzip zip software-properties-common build-essential make gcc g++ sudo cron dos2unix && \
    apt -y install \
        # Process managers
        supervisor \
        # install net packages useful for debugging
        iputils-ping telnet netcat lsof net-tools openssl dnsutils rsync bind9-host stress \
        # config file manipulation
        crudini xmlstarlet moreutils jq \
        # General purpose
        pwgen swaks vim nano cmake pkg-config openssh-client openssh-server uuid less zip file \
        # apache
        apache2 libapache2-mod-perl2 apache2-dev \
        # nginx
        nginx-full \
        # Databases (clients)
        sqlite3 mysql-client-8.0 redis-tools postgresql-client-14 ldap-utils && \
    apt -y update && \
    # Dev packages (useful for native modules in ruby, node)
    apt install -y gettext imagemagick graphicsmagick libcurl4 libcurl4-openssl-dev libexpat1-dev libffi-dev libgdbm-dev libicu-dev libmysqlclient-dev \
        libncurses5-dev libpq-dev libre2-dev libreadline-dev libssl-dev libxml2-dev libxslt-dev libyaml-dev zlib1g-dev \
        libmcrypt-dev libgmp-dev libfreetype6-dev libjpeg-dev libjpeg-turbo8-dev libpng-dev chrpath libxft-dev libfontconfig1-dev \
        libkrb5-dev libpq-dev libxslt1-dev libldap2-dev libsasl2-dev libtool libzmq3-dev locales-all locales libmagic1 \
    # perl
    perl libimage-exiftool-perl \
    # ruby
    ruby3.0 ruby3.0-dev \
    # Python 3
    python3-dev python3-pip uwsgi-plugin-python3 python3-setuptools virtualenv virtualenvwrapper \
    # php 8.1
    php8.1 php8.1-{bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,gmp,imap,interbase,intl,ldap,mbstring,mysql,odbc,opcache,pgsql,phpdbg,pspell,readline,snmp,soap,sqlite3,sybase,tidy,xml,xmlrpc,xsl,zip} libapache2-mod-php8.1 php-{apcu,date,imagick,gnupg,mailparse,pear,redis,smbclient,twig,uuid,validate,zmq} \
    # good to have!
    ghostscript libgs-dev ffmpeg x264 x265 && \
    # keep this here, otherwise it installs php 7.4
    apt install -y composer && \
    # Delete apt-cache and let people apt-update on start. Without this, we keep getting apt errors for --fix-missing
    rm -rf /var/cache/apt /var/lib/apt/lists

# mongo shell (https://www.mongodb.com/try/download/shell)
RUN curl https://downloads.mongodb.com/compass/mongodb-mongosh_1.6.1_amd64.deb -o /tmp/mongosh.deb && \
    dpkg -i /tmp/mongosh.deb && \
    rm /tmp/mongosh.deb && \
    mongosh --nodb --eval "disableTelemetry()"

# gosu
RUN curl -L https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64 -o /usr/local/bin/gosu && chmod +x /usr/local/bin/gosu

## the installations are kept separate since these change a lot compared to above
# node (https://nodejs.org/en/download/)
ARG NODEVERSION=18.12.1
RUN mkdir -p /usr/local/node-${NODEVERSION} && \
    curl -L https://nodejs.org/dist/v${NODEVERSION}/node-v${NODEVERSION}-linux-x64.tar.xz | tar Jxf - --strip-components 1 -C /usr/local/node-${NODEVERSION} && \
    PATH=/usr/local/node-${NODEVERSION}/bin:$PATH npm install --global yarn

# Go (https://golang.org/dl/)
ARG GOVERSION=1.19.3
ENV GOROOT /usr/local/go-${GOVERSION}
RUN mkdir -p /usr/local/go-${GOVERSION} && \
    curl -L https://storage.googleapis.com/golang/go${GOVERSION}.linux-amd64.tar.gz | tar zxf - -C /usr/local/go-${GOVERSION} --strip-components 1

# https://github.com/mikefarah/yq/releases
ARG YQVERSION=4.30.5
RUN curl -sL https://github.com/mikefarah/yq/releases/download/v${YQVERSION}/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq

# Keep bash history around as long as /run is alive. .dbshell is mongodb
RUN ln -sf /run/.bash_history /root/.bash_history && \
    ln -sf /run/.psql_history /root/.psql_history && \
    ln -sf /run/.mysql_history /root/.mysql_history && \
    ln -sf /run/.irb_history /root/.irb_history && \
    ln -sf /run/.inputrc /root/.inputrc && \
    ln -sf /run/.dbshell /root/.dbshell && \
    ln -sf /run/.mongorc.js /root/.mongorc.js

# Put node, go in the path by default
ENV PATH /usr/local/node-${NODEVERSION}/bin:$GOROOT/bin:$PATH

# add a non-previleged user that apps can use
# by default, account is created as inactive which prevents login via openssh
# https://github.com/gitlabhq/gitlabhq/issues/5304
RUN adduser --uid 1000 --disabled-login --gecos 'Cloudron' cloudron && \
    passwd -d cloudron

# add the two commonly used users to the volume group
RUN addgroup --gid 500 --system media && \
    usermod -a -G media cloudron && \
    usermod -a -G media www-data

# disable editor features which don't work with read-only fs
RUN echo "set noswapfile" >> /root/.vimrc && \
    echo "set noswapfile" >> /home/cloudron/.vimrc && \
    echo "unset historylog" >> /etc/nanorc

# this also sets /etc/default/locale (see detailed notes in README)
RUN update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8

# source any app specific rcfile
RUN echo -e "\n[[ -f /app/data/.bashrc ]] && source /app/data/.bashrc" >> /root/.bashrc

