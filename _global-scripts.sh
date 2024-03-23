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
  local location_prefix=""
  if [ ! -z "$PROJECT_TAG" ]; then
    location_prefix=" -l $PROJECT_URL "
  fi

  if project_uses_docker; then
    docker exec -it -u 1000 -w $PROJECT_PATH_IN_CONTAINER/web $PROJECT_NAME $PROJECT_PATH_IN_CONTAINER/vendor/bin/drush$location_prefix "$@"
  else
    $PROJECT_PATH/vendor/bin/drush$location_prefix $@
  fi
}

_project_global_script_mysql() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it $PROJECT_DB_CONTAINER_NAME mariadb -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD -h$PROJECT_DB_HOST $PROJECT_DB_NAME "$@"
  else
    mysql -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD -h$PROJECT_DB_HOST $PROJECT_DB_NAME "$@"
  fi
}

_project_global_script_mysql_root() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it $PROJECT_DB_CONTAINER_NAME mariadb -uroot -p$PROJECT_DB_ROOT_PASSWORD -h$PROJECT_DB_HOST "$@"
  else
    mysql -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD -h$PROJECT_DB_HOST $PROJECT_DB_NAME "$@"
  fi
}

_project_global_script_mysql_dump() {
  local backup_path=$(realpath $PROJECT_PATH/.project/dumps)
  if [ ! -z "$PROJECT_TAG" ]; then
    backup_path="$backup_path/$PROJECT_TAG"
    mkdir -p "$backup_path"
  fi

  local date=$(date +%F--%H-%M)
  local dump_file="${backup_path}/${date}--${PROJECT_NAME}_${PROJECT_ENV}.sql"
  # Strip the project path from the beginngin of $dump_file.
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

_project_global_script_import_mysql_dump() {
  local dump_file="$1"
  if [ ! -f "$dump_file" ]; then
    project_show_error "Could not find sql dump: \"${PROJECT_TEXT_YELLOW}${dump_file}${PROJECT_TEXT_RESET}\"."
    return 1
  fi

  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -i $PROJECT_DB_CONTAINER_NAME mariadb -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD $PROJECT_DB_NAME -h$PROJECT_DB_CONTAINER_NAME < $dump_file
  else
    mariadb -u$PROJECT_DB_USER -p$PROJECT_DB_PASSWORD $PROJECT_DB_NAME -h$PROJECT_DB_CONTAINER_NAME < $dump_file
  fi 
}

_project_global_script_list_mysql_dumps() {
dump_file local dumps_path=$(realpath $PROJECT_PATH/.project/dumps)
  ls -lh $dumps_path | tail -n +2 | while read -r line; do
    # Extract file name
    file=$(echo "$line" | awk '{print $9 " (" $5 ")"}')

    # Print formatted output
    echo "$file"
done
}

_project_global_script_composer() {
  if project_uses_docker; then
    docker exec -u 1000 -it -w $PROJECT_PATH_IN_CONTAINER $PROJECT_CONTAINER_NAME composer "$@"
  else
    $PROJECT_COMPOSER_BIN_ON_HOST "$@"
  fi
}

_project_global_script_build_theme() {
  docker run \
    -it \
    --rm \
    --user "$PROJECT_CONTAINER_UID" \
    --workdir "$PROJECT_PATH_IN_CONTAINER/$PROJECT_NPM_ROOT" \
    --name "${PROJECT_CONTAINER_NAME}_npm" \
    --volume "$PROJECT_PATH:$PROJECT_PATH_IN_CONTAINER" \
    node:alpine \
    npm run build
}

_project_global_script_enter() {
  if project_uses_docker; then
    docker exec -it -u 1000 -w $PROJECT_PATH_IN_CONTAINER $PROJECT_NAME /bin/bash
  else
    project_show_error "This environment is configured not to use docker!"
    exit 1
  fi
}

_project_global_script_npm() {
  local uid="$1"
  local workdir="$2"
  shift 2

  docker run \
    -it \
    --rm \
    --user "$uid" \
    --workdir "$workdir" \
    --name "${PROJECT_CONTAINER_NAME}_npm" \
    --volume "$PROJECT_PATH:$PROJECT_PATH_IN_CONTAINER" \
    node:alpine \
    npm "$@"
}

_project_global_script_vite() {
  docker run \
    -it \
    --rm \
    --user "$PROJECT_CONTAINER_UID" \
    --workdir "$PROJECT_PATH_IN_CONTAINER/$PROJECT_NPM_ROOT" \
    --name "${PROJECT_CONTAINER_NAME}_npm" \
    -p $PROJECT_VITE_PORT_ON_HOST:$PROJECT_VITE_PORT \
    --volume "$PROJECT_PATH:$PROJECT_PATH_IN_CONTAINER" \
    node:alpine \
    npm run start
}

_project_global_script_rebuild_containers() {
  if project_uses_docker; then
    local container_name="$1"
    local compose_file=$(project_get_docker_compose_path)

    if [ -z "$container_name" ]; then
      docker compose -f "$compose_file" build app
    else
      docker compose -f "$compose_file" build "$container_name"
    fi
  else
    project_show_error "This environment is configured not to use docker!"
    exit 1
  fi
}

_project_global_script_compare_with_project() {
  local relative_filename="$1"
  local project_name="$2"
  local diff_viewer="meld"

  if [ -z "$relative_filename" ]; then
    project_show_error "You need to provide a filename to compare."
    return 1
  fi

  if ! type meld &> /dev/null; then
    if type vimdiff &> /dev/null; then
      diff_viewer="vimdiff"
    else
      diff_viewer="diff"
    fi
  fi 

  filename=$(realpath "$relative_filename")

  # Normalize relative_name to be relative to $PROJECT_PATH.
  local project_path=$(_project_get_project_path)
  relative_filename="${filename#$project_path}"

  if [ ! -f "$filename" ] && [ ! -d "$filename" ]; then
    project_show_error "Could not find file \"${PROJECT_TEXT_YELLOW}${filename}${PROJECT_TEXT_RESET}\" in this project."
    return 1
  fi

  if [ ! $? -eq 0 ]; then
    project_show_error "Could not find project \"${PROJECT_TEXT_YELLOW}${project_name}${PROJECT_TEXT_RESET}\"."
    return 1
  fi

  local other_project_path=$(_project_get_project_path_by_name "$project_name")
  local filename_in_other_project="$other_project_path/$relative_filename"

  if [ ! -f "$filename_in_other_project" ] && [ ! -d "$filename_in_other_project" ]; then
    project_show_error "Could not find file \"${PROJECT_TEXT_YELLOW}${filename_in_other_project}${PROJECT_TEXT_RESET}\" in project \"${PROJECT_TEXT_YELLOW}${project_name}${PROJECT_TEXT_RESET}\"."
    return 1
  fi

  $diff_viewer "$filename" "$filename_in_other_project"
}

_project_global_script_create_drupal_hash_salt() {
  local do_write=false
  if [ ! -z "$PROJECT_DRUPAL_HASH_SALT" ]; then
    project_show_warning "POJECT_DRUPAL_HASH_SALT is currently not empty: $PROJECT_DRUPAL_HASH_SALT"
    read -p "Create a new one and overwrite it? (y/n): " overwrite

    case "$overwrite" in
      [yY][eE][sS]|[yY]) 
      do_write=true
      ;;
      *) 
        project_show_warning "Aborted."
        return 1
      ;;
    esac

    if $do_write; then
      local hash_salt=$(project_run_global_script drush php:eval 'echo \Drupal\Component\Utility\Crypt::randomBytesBase64(55) . "\n";')
      sed -i "s/^PROJECT_DRUPAL_HASH_SALT.*/PROJECT_DRUPAL_HASH_SALT=$hash_salt/" .env
      project_show_success "Set PROJECT_DRUPAL_HASH_SALT to ${hash_salt}"
    fi

  fi
}

_project_global_script_update_drupal_core() {
  project_run_global_script composer update "drupal/core-*" --with-all-dependencies
}

_project_create_nginx_config() {
  local output_file="$1"
  # '^^' Makes the value of PROJECT_ENV all caps.
  local env_var_name="PROJECT_NGINX_TEMPLATE_${PROJECT_ENV^^}"

  # Get the value of a variable whose name is store in env_var_name.
  local template
  template="${!env_var_name}"

  project_render_template "$template"\
   container_name "$PROJECT_CONTAINER_NAME"\
   container_port "$PROJECT_CONTAINER_PORT"\
   domain "$PROJECT_DOMAIN"\
   root_in_container "$PROJECT_PATH_IN_CONTAINER/web"\
  > $output_file

  if [ $? -eq 0 ]; then
    project_show_success "Created nginx configuration \"${PROJECT_TEXT_YELLOW}${output_file}${PROJECT_TEXT_RESET}\"."
  fi
}
