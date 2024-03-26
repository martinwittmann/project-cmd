ARG APP_ENV=dev
FROM schwerpunkt/php-8.1:${APP_ENV}

ARG CONTAINER_UID=1000

# Create a user we can use later to run commands.
RUN adduser web -u $CONTAINER_UID --disabled-password --gecos ""