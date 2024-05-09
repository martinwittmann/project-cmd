#!/bin/bash

_init_project() {
  project docker compose_update

  project_show_success "Created project files for \"${TEXT_YELLOW}${PROJECT_NAME}${TEXT_RESET}\"."

  # The database is created via docker compose env variables of the mariadb container.

  echo "Starting project..."
  # Start the project / container not in dev-mode and hide the url since we need
  # to install the site.
  project start "" "1"

  echo "Installing drupal files via composer..."
  project run composer create-project "$PROJECT_DRUPAL_COMPOSER_PACKAGE" "$PROJECT_PATH_IN_CONTAINER"

  echo "Executing drush site-install..."
  local db_url
  db_url=$(project_format_url "mysql" "$PROJECT_DB_USER" "$PROJECT_DB_PASSWORD" "$PROJECT_DB_HOST" "$PROJECT_DB_PORT" "$PROJECT_DB_NAME")
  local admin_password
  admin_password=$(project_create_passphrase 16)
  project_run_global_script "drupal_install_site" "standard" "$PROJECT_NAME" "$PROJECT_DRUPAL_LOCALE" "$db_url" "$PROJECT_DRUPAL_ADMIN_USER" "$admin_password" "$PROJECT_DRUPAL_ADMIN_EMAIL"


  echo "Adding project to proxy..."
  project_run_global_script "add_to_proxy"

  if [ -n "$PROJECT_PROXY_DOCKER_VOLUMES" ]; then
    # If this project added docker volumes we need to fully restart the proxy.
    project -p "$PROJECT_PROXY_PROJECT_NAME" restart
  else
    # If only nginx configurations were added/changed, a reload is enough.
    project -p "$PROJECT_PROXY_PROJECT_NAME" run reload
  fi

  project_show_success "Done setting up + installing drupal project \"${TEXT_YELLOW}${PROJECT_NAME}${TEXT_RESET}\"."
  _project_print_url "$PROJECT_URL"
}

_init_project
