#!/bin/bash

_init_project() {
  project docker compose_update

  project_show_success "Created project files for \"${TEXT_YELLOW}${PROJECT_NAME}${TEXT_RESET}\"."

  # The database is created via docker compose env variables of the mariadb container.
  # But we need to create passwords for the db:
  local env_file
  env_file=$(_project_get_default_env_file "$PROJECT_NAME")
  PROJECT_DB_PASSWORD=$(project_create_passphrase 16)
  project_set_env_file_variable "$env_file" "PROJECT_DB_PASSWORD" "$PROJECT_DB_PASSWORD" "1" "1"

  PROJECT_DB_ROOT_PASSWORD=$(project_create_passphrase 16)
  project_set_env_file_variable "$env_file" "PROJECT_DB_ROOT_PASSWORD" "$PROJECT_DB_ROOT_PASSWORD" "1" "1"

  if [ "$PROJECT_ENV" == "dev" ]; then
    # Add the project path to the proxy docker volumes, since that is what we
    # need to do on dev systems.
    PROJECT_PROXY_DOCKER_VOLUMES="${PROJECT_PATH}:/srv/${PROJECT_DOMAIN}"
    project_set_env_file_variable "$env_file" "PROJECT_PROXY_DOCKER_VOLUMES" "$PROJECT_PROXY_DOCKER_VOLUMES" "1" "1"
  fi

  echo "Starting project..."
  # Start the project / container not in dev-mode and hide the url since we need
  # to install the site.
  project start "" "1"

  local drupal_path="drupal"
  echo -e "Installing drupal files in \"${TEXT_YELLOW}./$drupal_path${TEXT_RESET}\" via composer..."
  # We need to create the drupal project in an empty directory as composer refuses
  # to create a project in a non-empty directory.
  local drupal_install_path="$PROJECT_PATH/$drupal_path"
  if [ "$drupal_install_path" == "/" ]; then
    project_show_error "Invalid drupal installation path."
  fi
  mkdir "$PROJECT_PATH/$drupal_path"
  project run composer create-project "$PROJECT_DRUPAL_COMPOSER_PACKAGE" "$PROJECT_PATH_IN_CONTAINER/$drupal_path"
  # Copy the files created by create-project to our project path and delete the drupal_path.
  rsync "${drupal_path}/" "${PROJECT_PATH}/" -a
  if [ $? -ne 0 ]; then
    project_show_error "Error creating drupal project scaffold from \"${TEXT_YELLOW}${PROJECT_DRUPAL_COMPOSER_PACKAGE}${TEXT_RESET}\"."
    return 1
  fi

  rm "${drupal_install_path}" -r
  # Allow the owner to create files in sites/default.
  sudo chmod 755 "$PROJECT_PATH/web/sites/default"
  sudo chgrp www-data "$PROJECT_PATH/web/sites/default/files" -R
  sudo chmod 755 "$PROJECT_PATH/web/sites/default/files" -R

  # Update all required files with values from .env.
  project_run_global_script "update_drupal_env_values"

  #echo "Installing drush..."
  project run composer require drush/drush

  echo "Executing drush site-install..."
  local db_url
  db_url=$(project_format_url "mysql" "$PROJECT_DB_USER" "$PROJECT_DB_PASSWORD" "$PROJECT_DB_HOST" "$PROJECT_DB_PORT" "$PROJECT_DB_NAME")
  local admin_password
  admin_password=$(project_create_passphrase 16)
  project_run_global_script "drupal_install_site_interactive"

  echo "Adding project to proxy..."
  project_run_global_script "add_project_to_proxy"

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
