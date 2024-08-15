FROM php:8.0-fpm

ARG APP_ENV

# Note that we use docker run for installing packages + adding php extensions,
# because this way we can use docker's layers to cache those changes and speed up
# container build times.
RUN apt-get update && apt-get install -y git vim curl libcurl4-gnutls-dev libxml2-dev libpng-dev libssl-dev libzip-dev default-mysql-client unzip libc-client-dev libkrb5-dev libjpeg-dev libwebp-dev libfreetype6-dev
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl
RUN docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype
RUN docker-php-ext-install gd pdo_mysql zip imap bcmath

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY container_setup.sh /
RUN /container_setup.sh