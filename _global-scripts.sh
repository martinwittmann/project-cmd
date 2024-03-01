#!/bin/bash

project_run_global_script() {
  local script_name="$1"
  shift

  if [ -z "$script_name" ]; then
    project_show_error "You need to provide a script name."
  fi

  local function_name="_project_global_script_$script_name"
  "$function_name" "$@"
}

_project_global_script_start() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    if ! systemctl is-active --quiet docker; then
      sudo systemctl start docker
    fi

    local compose_file="docker-compose.${PROJECT_ENV}.yml"
    docker compose -f "$PROJECT_PATH/$compose_file" up -d --remove-orphans
  else
    project_show_error "I don\'t know how to start project \"${PROJECT_TEXT_YELLOW}${PROJECT_NAME}${PROJECT_TEXT_RESET}\" since it is not configured to use docker and no start script is specified."
  fi
}

_project_global_script_stop() {
  echo "$PROJECT_PATH"
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker compose -f "$PROJECT_PATH/docker-compose.${PROJECT_ENV}.yml" down
  else
    project_show_error "I don\'t know how to stop this project since it is not configured to use docker and no start script is specified."
  fi
}

_project_global_script_enter_root() {
  docker exec -it --user root -w $PROJECT_PATH_IN_CONTAINER $PROJECT_NAME /bin/bash
}

_project_global_script_drush() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it -u 1000 -w $PROJECT_PATH_IN_CONTAINER/web $PROJECT_NAME $PROJECT_PATH_IN_CONTAINER/vendor/bin/drush "$@"
  else
    $PROJECT_PATH/vendor/bin/drush $@
  fi
}

_project_global_script_composer() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    sudo docker exec -u 1000 -it -w $PROJECT_PATH_IN_CONTAINER $PROJECT_CONTAINER_NAME composer "$@"
  else
    $PROJECT_COMPOSER_BIN_ON_HOST "$@"
  fi
}

_project_global_script_build_theme() {
  local theme_path="$PROJECT_PATH_IN_CONTAINER$PROJECT_THEME_PATH/"
  sudo docker exec -u 1000 -it -w $theme_path $PROJECT_CONTAINER_NAME npm run build "$@"
}

_project_global_script_enter() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it -u 1000 -w $PROJECT_PATH_IN_CONTAINER $PROJECT_NAME /bin/bash
  else
    echo "This environment is configured not to use docker!"
    exit 1
  fi
}

