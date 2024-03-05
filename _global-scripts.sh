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
  if project_uses_docker; then
    if ! systemctl is-active --quiet docker; then
      sudo systemctl start docker
    fi

    local compose_file=$(project_get_docker_compose_path)
    # We always daemonize and remove orphans to not accumulate old containers.
    docker compose -f "$compose_file" up -d --remove-orphans
  else
    project_show_error "I don\'t know how to start project \"${PROJECT_TEXT_YELLOW}${PROJECT_NAME}${PROJECT_TEXT_RESET}\" since it is not configured to use docker and no start script is specified."
  fi
}

_project_global_script_stop() {
  if project_uses_docker; then
    local compose_file=$(project_get_docker_compose_path)
    docker compose -f "$compose_file" down
  else
    project_show_error "I don\'t know how to stop this project since it is not configured to use docker and no start script is specified."
  fi
}

_project_global_script_restart() {
  _project_global_script_stop
  _project_global_script_start
}

_project_global_script_root() {
  docker exec -it --user root -w $PROJECT_PATH_IN_CONTAINER $PROJECT_NAME /bin/bash
}

_project_global_script_nginx_access() {
  tail -f .project/logs/nginx_access.log
}

_project_global_script_nginx_error() {
  tail -f .project/logs/nginx_error.log
}

_project_global_script_drush() {
  if project_uses_docker; then
    docker exec -it -u 1000 -w $PROJECT_PATH_IN_CONTAINER/web $PROJECT_NAME $PROJECT_PATH_IN_CONTAINER/vendor/bin/drush "$@"
  else
    $PROJECT_PATH/vendor/bin/drush $@
  fi
}

_project_global_script_mysql() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it $PROJECT_DB_CONTAINER_NAME mariadb -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD -h$PROJECT_DB_HOST $PROJECT_DB_NAME "$@"
  else
    mysql -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD -h$PROJECT_DB_HOST $PROJECT_DB_NAME "$@"
  fi
}

_project_global_script_mysql_dump() {
  local backup_path=$(realpath $PROJECT_PATH/.project/dumps)
  local date=$(date +%F--%H-%M)
  local dump_file="${backup_path}/${date}--${PROJECT_NAME}_${PROJECT_ENV}.sql"
  local short_name="${dump_file#$PROJECT_PATH}"

  echo -e "Creating database dump at \"${PROJECT_TEXT_YELLOW}${short_name}${PROJECT_TEXT_RESET}\"..."
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it $PROJECT_DB_CONTAINER_NAME mariadb-dump -h$PROJECT_DB_HOST -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD $PROJECT_DB_NAME > $dump_file
  else
    mariadb-dump -h$PROJECT_DB_HOST -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD $PROJECT_DB_NAME > $dump_file
  fi

  if [ $? -eq 0 ]; then
    local size=`du -h $dump_file | cut -f -1`
    project_show_success "Created db dump: $short_name ($size)."
  fi
}

_project_global_script_list_mysql_dumps() {
  local dumps_path=$(realpath $PROJECT_PATH/.project/dumps)
  ls -lh $dumps_path | tail -n +2 | while read -r line; do
    # Extract file name
    file=$(echo "$line" | awk '{print $9 " (" $5 ")"}')

    # Print formatted output
    echo "$file"
done
}

_project_global_script_composer() {
  if project_uses_docker; then
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
  if project_uses_docker; then
    docker exec -it -u 1000 -w $PROJECT_PATH_IN_CONTAINER $PROJECT_NAME /bin/bash
  else
    echo "This environment is configured not to use docker!"
    exit 1
  fi
}

_project_global_script_build_theme() {
  docker run \
  --user "$PROJECT_CONTAINER_UID" \
  --workdir "$PROJECT_PATH_IN_CONTAINER/$PROJECT_THEME_PATH" \
  --name "${PROJECT_PROJECT_CONTAINER_NAME}_build_theme" \
  --volume "$PROJECT_PATH:$PROJECT_PATH_IN_CONTAINER" \
  node \
  npm run start
}

_project_global_script_rebuild_containers() {
  if project_uses_docker; then
    local compose_file=$(project_get_docker_compose_path)
    docker compose -f "$compose_file" build
  else
    echo "This environment is configured not to use docker!"
    exit 1
  fi
}
