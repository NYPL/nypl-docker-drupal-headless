FROM dockette/php:5.6-fpm

#ENV PHP_VERSION 5.6

RUN apt-get update && apt-get dist-upgrade -y && \
    # DEPENDENCIES #############################################################
    apt-get install -y wget curl apt-transport-https ca-certificates && \
    # PHP DEB.SURY.CZ ##########################################################
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ jessie main" > /etc/apt/sources.list.d/php.list && \
    apt update && \
    apt install -y --no-install-recommends \
        # Mysql-client added to support eg. drush sqlc
        mysql-client \
        # Git and unzip are required by composer
        git \
        unzip \
        wget \
        dnsutils \
        curl \
        iputils-ping \
        telnet \
        imagemagick \
    && \
    php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -ms /bin/bash docker
USER docker
WORKDIR /home/docker

# Copy source files and directories to the working directory
ADD . /home/docker

# Install composer dependencies
RUN composer install --no-dev --prefer-dist --optimize-autoloader --no-scripts
RUN composer global require drush/drush:8.x

# Pull down custom Drupal installation profile repo for drush build
#RUN git clone git@bitbucket.org:NYPL/dru_profiles_wwwnyplorg ./dru_profiles_wwwnyplorg

USER root
# Reset the www directory to our custom PHP application
RUN rm -rf ./www
RUN ./.composer/vendor/bin/drush make --prepare-install ./repo/build-nypl-org.make ./www

RUN cp -R ./nypl ./www/sites/all/modules/custom
RUN cp -R ./repo ./www/profiles/nyplorg
RUN cp -R ./www/* /var/www/html/
#RUN cp /home/docker/php.ini /etc/php/5.6/cli
#RUN cp /home/docker/php.ini /etc/php/5.6/fpm
