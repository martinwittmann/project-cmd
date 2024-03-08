#!/bin/bash

# We do not install packages or php extensions here. See Dockerfile why.


# Configure php for development setups.
if [ "$APP_ENV" == "dev" ]; then
  sed -i "s/^max_execution_time.*/max_execution_time = 240/" /usr/local/etc/php/php.ini-development
  sed -i "s/^;\?max_input_vars.*/max_input_vars = 10000/" /usr/local/etc/php/php.ini-development
  sed -i "s/^memory_limit.*/memory_limit = 1024M/" /usr/local/etc/php/php.ini-development
  sed -i "s/^display_errors.*/display_errors = on/" /usr/local/etc/php/php.ini-development
  sed -i "s/^display_startup_errors.*/display_startup_errors = on/" /usr/local/etc/php/php.ini-development
  sed -i "s/^post_max_size.*/post_max_size = 200M/" /usr/local/etc/php/php.ini-development
  sed -i "s/^upload_max_filesize.*/upload_max_filesize = 100M/" /usr/local/etc/php/php.ini-development
  sed -i "s/^mail\.add_x_header.*/mail\.add_x_header = on/" /usr/local/etc/php/php.ini-development
  sed -i "s/^session\.cookie_lifetime.*/session\.cookie_lifetime = 2678400/" /usr/local/etc/php/php.ini-development
  sed -i "s/^;zend_extension=opcache.*/zend_extension=opcache/" /usr/local/etc/php/php.ini-development
  sed -i "s/^;opcache\.enable.*/opcache.enable = 1/" /usr/local/etc/php/php.ini-development
  sed -i "s/^;opcache\.enable_cli.*/opcache.enable_cli= 0/" /usr/local/etc/php/php.ini-development
  sed -i "s/^;opcache\.revalidate_freq.*/opcache.revalidate_freq = 1/" /usr/local/etc/php/php.ini-development

  # NOTE:
  # We're setting variables_order to EGPCS to allow environment variables to be available in php.
  sed -i "s/^variables_order.*/variables_order = \"EGPCS\"/" /usr/local/etc/php/php.ini-development

  cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
else
  sed -i "s/^max_execution_time.*/max_execution_time = 240/" /usr/local/etc/php/php.ini-production
  sed -i "s/^;\?max_input_vars.*/max_input_vars = 2000/" /usr/local/etc/php/php.ini-production
  sed -i "s/^memory_limit.*/memory_limit = 512M/" /usr/local/etc/php/php.ini-production
  sed -i "s/^display_errors.*/display_errors = off/" /usr/local/etc/php/php.ini-production
  sed -i "s/^display_startup_errors.*/display_startup_errors = off/" /usr/local/etc/php/php.ini-production
  sed -i "s/^post_max_size.*/post_max_size = 50M/" /usr/local/etc/php/php.ini-production
  sed -i "s/^upload_max_filesize.*/upload_max_filesize = 20M/" /usr/local/etc/php/php.ini-production
  sed -i "s/^mail\.add_x_header.*/mail\.add_x_header = on/" /usr/local/etc/php/php.ini-production
  sed -i "s/^session\.cookie_lifetime.*/session\.cookie_lifetime = 2678400/" /usr/local/etc/php/php.ini-production
  sed -i "s/^;zend_extension=opcache.*/zend_extension=opcache/" /usr/local/etc/php/php.ini-production
  sed -i "s/^;opcache\.enable.*/opcache.enable = 1/" /usr/local/etc/php/php.ini-production
  sed -i "s/^;opcache\.enable_cli.*/opcache.enable_cli= 0/" /usr/local/etc/php/php.ini-production
  sed -i "s/^;opcache\.revalidate_freq.*/opcache.revalidate_freq = 10/" /usr/local/etc/php/php.ini-production

  # NOTE:
  # We're setting variables_order to EGPCS to allow environment variables to be available in php.
  sed -i "s/^variables_order.*/variables_order = \"EGPCS\"/" /usr/local/etc/php/php.ini-production

  cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
fi

# The default causes some errors to be logged but not displayed in the browser on php 8.1 for some reason.
# See https://github.com/docker-library/php/issues/878
# TODO Remove this, when a fixed version is released.
sed -i "s/^;\?log_limit.*/log_limit = 1024/" /usr/local/etc/php-fpm.d/docker.conf

if [ ${APP_ENV} == "dev" ] || [ ${APP_ENV} == "development" ]; then
  # As per https://www.drupal.org/project/drupal/issues/3405976#comment-15346751
  # xdebug 3.3 causes problems at least when running drush. To work around this
  # issue we install the latest version known to be working.
  # TODO Remove version constraint when the bug is fixed.
  pecl install xdebug-3.2.2 && docker-php-ext-enable xdebug
  echo "xdebug.mode=develop,debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
  echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
  echo "xdebug.discover_client_host=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
  echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
  echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
  echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;
fi
