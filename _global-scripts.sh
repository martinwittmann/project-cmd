#!/bin/bash

project_run_global_script() {
  local script_name="$1"
  shift

  if [ -z "$script_name" ]; then
    project_show_error "You need to provide a script name."
    return 1
  fi

  local function_name="_project_global_script_$script_name"
  "$function_name" "$@"
}

_project_global_script_start() {
  if project_uses_docker; then
    if ! systemctl is-active --quiet docker; then
      sudo systemctl start docker
    fi

    local compose_file
    compose_file="$(project_get_docker_compose_path)"

    # We always daemonize and remove orphans to not accumulate old containers.
    docker compose -f "$compose_file" up -d --remove-orphans
  else
    project_show_error "I don\'t know how to start project \"${p["_text_yellow"]}$PROJECT_NAME${p["_text_reset"]}\" since it is not configured to use docker and no start script is specified."
    return 1
  fi
}

_project_global_script_stop() {
  if project_uses_docker; then
    local compose_file
    compose_file="$(project_get_docker_compose_path)"
    docker compose -f "$compose_file" down
  else
    project_show_error "I don\'t know how to stop this project since it is not configured to use docker."
    return 1
  fi
}

_project_global_script_restart() {
  _project_global_script_stop
  _project_global_script_start
}

_project_global_script_root() {
  docker exec -it --user root -w "$PROJECT_PATH_IN_CONTAINER" "$PROJECT_NAME" /bin/bash
}

_project_global_script_nginx_access() {
  local logs_dir
  logs_dir="$(_project_get_logs_dir "$PROJECT_NAME")"
  tail -f "$PROJECT_PATH/$logs_dir/${PROJECT_DOMAIN}_access.log"
}

_project_global_script_nginx_error() {
  local logs_dir
  logs_dir="$(_project_get_logs_dir "$PROJECT_NAME")"
  tail -f "$PROJECT_PATH/$logs_dir/${PROJECT_DOMAIN}_error.log"
}

_project_global_script_drush() {
  local location_prefix=""
  if [ -n "${p["project_tag"]}" ]; then
    location_prefix=" -l $PROJECT_URL "
  fi

  if project_uses_docker; then
    docker exec -it -u 1000 -w "$PROJECT_PATH_IN_CONTAINER/web" "$PROJECT_NAME" "$PROJECT_PATH_IN_CONTAINER/vendor/bin/drush$location_prefix" "$@"
  else
    "$PROJECT_PATH/vendor/bin/drush$location_prefix" "$@"
  fi
}

_project_global_script_mysql() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it "$PROJECT_DB_CONTAINER_NAME" mariadb -u"$PROJECT_DB_USER" -p"$PROJECT_DB_PASSWORD" -h"$PROJECT_DB_HOST" "$PROJECT_DB_NAME" "$@"
  else
    mysql -u"$PROJECT_DB_USER" -p"$PROJECT_DB_PASSWORD" -h"$PROJECT_DB_HOST" "$PROJECT_DB_NAME" "$@"
  fi
}

_project_global_script_mysql_root() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it "$PROJECT_DB_CONTAINER_NAME" mariadb -uroot -p"$PROJECT_DB_ROOT_PASSWORD" -h"$PROJECT_DB_HOST" "$@"
  else
    mysql -u"$PROJECT_DB_USER" -p"$PROJECT_DB_PASSWORD" -h"$PROJECT_DB_HOST" "$PROJECT_DB_NAME" "$@"
  fi
}

_project_global_script_mysql_dump() {
  local backup_path
  backup_path="$(realpath "$PROJECT_PATH/.project/dumps")"
  if [ -n "${p["project_tag"]}" ]; then
    backup_path="$backup_path/${p["project_tag"]}"
    mkdir -p "$backup_path"
  fi

  local date
  date="$(date +%F--%H-%M)"
  local dump_file="${backup_path}/${date}--${PROJECT_NAME}_${PROJECT_ENV}.sql"
  # Strip the project path from the beginning of $dump_file.
  local short_name="${dump_file#$PROJECT_PATH}"

  echo -e "Creating database dump at \"${p["_text_yellow"]}${short_name}${p["_text_reset"]}\"..."
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -it "$PROJECT_DB_CONTAINER_NAME" mariadb-dump -h"$PROJECT_DB_HOST" -u"$PROJECT_DB_USER" -p"$PROJECT_DB_PASSWORD" "$PROJECT_DB_NAME" > "$dump_file"
  else
    mariadb-dump -h"$PROJECT_DB_HOST" -u"$PROJECT_DB_USER" -p"$PROJECT_DB_PASSWORD" "$PROJECT_DB_NAME" > "$dump_file"
  fi

  if [ $? -eq 0 ]; then
    local size
    size="$(du -h "$dump_file" | cut -f -1)"
    project_show_success "Created db dump: $short_name ($size)."
  fi
}

_project_global_script_import_mysql_dump() {
  local dump_file="$1"
  if [ ! -f "$dump_file" ]; then
    project_show_error "Could not find sql dump: \"${p["_text_yellow"]}${dump_file}${p["_text_reset"]}\"."
    return 1
  fi

  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    docker exec -i "$PROJECT_DB_CONTAINER_NAME" mariadb -u"$PROJECT_DB_USER" -p"$PROJECT_DB_PASSWORD" "$PROJECT_DB_NAME" -h"$PROJECT_DB_CONTAINER_NAME" < "$dump_file"
  else
    mariadb -u"$PROJECT_DB_USER" -p"$PROJECT_DB_PASSWORD" "$PROJECT_DB_NAME" -h"$PROJECT_DB_CONTAINER_NAME" < "$dump_file"
  fi 
}

_project_global_script_list_mysql_dumps() {
  local dumps_path
  dumps_path="$(realpath "$PROJECT_PATH/.project/dumps")"
  ls -lh "$dumps_path" | tail -n +2 | while read -r line; do
    # Extract file name
    file=$(echo "$line" | awk '{print $9 " (" $5 ")"}')

    # Print formatted output
    echo "$file"
done
}

_project_global_script_composer() {
  if project_uses_docker; then
    docker exec -u 1000 -it -w "$PROJECT_PATH_IN_CONTAINER" "$PROJECT_CONTAINER_NAME" composer "$@"
  elif [ -n "$PROJECT_COMPOSER_BIN_ON_HOST" ]; then
    "$PROJECT_COMPOSER_BIN_ON_HOST" "$@"
  elif type composer &> /dev/null; then
    composer
  else
    project_show_error "Could not find composer bin to run on host.\nThis project is not configured to use docker."
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
    docker exec -it -u 1000 -w "$PROJECT_PATH_IN_CONTAINER" "$PROJECT_NAME" /bin/bash
  else
    project_show_error "This environment is configured not to use docker!"
    return 1
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
    -p "$PROJECT_VITE_PORT_ON_HOST:$PROJECT_VITE_PORT" \
    --volume "$PROJECT_PATH:$PROJECT_PATH_IN_CONTAINER" \
    node:alpine \
    npm run start
}

_project_global_script_rebuild_containers() {
  if project_uses_docker; then
    local container_name="$1"
    local compose_file
    compose_file="$(project_get_docker_compose_path)"

    if [ -z "$container_name" ]; then
      docker compose -f "$compose_file" build app
    else
      docker compose -f "$compose_file" build "$container_name"
    fi
  else
    project_show_error "This environment is configured not to use docker!"
    return 1
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

  filename="$(realpath "$relative_filename")"

  # Normalize relative_name to be relative to $PROJECT_PATH.
  local project_path
  project_path="$(_project_get_project_path)"
  relative_filename="${filename#$project_path}"

  if [ ! -f "$filename" ] && [ ! -d "$filename" ]; then
    project_show_error "Could not find file \"${p["_text_yellow"]}${filename}${p["_text_reset"]}\" in this project."
    return 1
  fi

  if [ ! $? -eq 0 ]; then
    project_show_error "Could not find project \"${p["_text_yellow"]}${project_name}${p["_text_reset"]}\"."
    return 1
  fi

  local other_project_path
  other_project_path="$(_project_get_project_path_by_name "$project_name")"
  local filename_in_other_project="$other_project_path/$relative_filename"

  if [ ! -f "$filename_in_other_project" ] && [ ! -d "$filename_in_other_project" ]; then
    project_show_error "Could not find file \"${p["_text_yellow"]}${filename_in_other_project}${p["_text_reset"]}\" in project \"${p["_text_yellow"]}${project_name}${p["_text_reset"]}\"."
    return 1
  fi

  $diff_viewer "$filename" "$filename_in_other_project"
}

_project_global_script_create_drupal_hash_salt() {
  local do_write=false
  if [ -n "$PROJECT_DRUPAL_HASH_SALT" ]; then
    project_show_warning "PROJECT_DRUPAL_HASH_SALT is currently not empty: $PROJECT_DRUPAL_HASH_SALT"
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
      local hash_salt
      hash_salt="$(project_run_global_script drush php:eval 'echo \Drupal\Component\Utility\Crypt::randomBytesBase64(55) . "\n";')"
      sed -i "s/^PROJECT_DRUPAL_HASH_SALT.*/PROJECT_DRUPAL_HASH_SALT=$hash_salt/" .env
      project_show_success "Set PROJECT_DRUPAL_HASH_SALT to ${hash_salt}"
    fi

  fi
}

_project_global_script_update_drupal_core() {
  project_run_global_script composer update "drupal/core-*" --with-all-dependencies
}

# Create
_project_global_script_create_nginx_config() {
  local template="$1"
  local output_file="$2"
  local overwrite_existing="${3:-0}"

  # If no template was provided try to get it from an environment variable.
  if [ -z "$template" ]; then
    template="$PROJECT_NGINX_TEMPLATE"

    if [ -z "$template" ]; then
      project_show_error "Project-cmd global script \"create_nginx_config\": You need to provide either a template as second argument or set the PROJECT_NGINX_TEMPLATE environment variable in the project for which the template should be generated."
      return 1
    fi
  fi

  if [ -f "$output_file" ] && [ "$overwrite_existing" -eq 0 ]; then
    project_show_error "The output file \"${p["_text_yellow"]}${output_file}${p["_text_reset"]}\" already exists.\nSet the third argument of the create_nginx_config global script to 1 to allow overwriting it."
    return 1
  fi

  local project_path
  project_path="$(_project_get_project_path_by_name "$project_name")"
  # Project domain needs to be retrieved via _project_get_env_value to respect
  # project tags.
  local project_domain
  project_domain="$(_project_get_env_value "$project_name" PROJECT_DOMAIN)"
  local path_in_proxy
  path_in_proxy="$(_project_get_env_value "$project_name" PROJECT_PATH_IN_PROXY_CONTAINER "" "/srv/${project_domain}")"
  path_in_container="$(_project_get_env_value "$project_name" PROJECT_PATH_IN_CONTAINER "" "/srv/app")"
  local logs_dir
  logs_dir="$(_project_get_logs_dir "$project_name")"

  local access_log_filename="$path_in_proxy/$logs_dir/${project_domain}_access.log"
  local error_log_filename="$path_in_proxy/$logs_dir/${project_domain}_error.log"

  project_render_template "$template"\
   container_name "$PROJECT_CONTAINER_NAME"\
   container_port "$PROJECT_CONTAINER_PORT"\
   domain "$project_domain"\
   path_in_container "$path_in_container"\
   path_in_proxy_container "$path_in_proxy"\
   access_log_filename "$access_log_filename"\
   error_log_filename "$error_log_filename"\
  > "$output_file"

  if [ $? -eq 0 ]; then
    project_show_success "Created nginx configuration \"${p["_text_yellow"]}${output_file}${p["_text_reset"]}\"."
  fi
}

_project_global_script_update_php_env() {
  _project_update_php_env "$@"
}

_project_global_script_create_nginx_config_for_project() {
  local project_name="$1"
  local template="$2"
  local proxy_project_name="$3"
  local allow_overwriting="${4:-0}"

  if [ -z "$project_name" ]; then
    project_show_error "You need to provide a project name."
    return 1
  fi

  if ! _project_get_project_path_by_name "$project_name" > /dev/null; then
    project_show_error "Project \"${PROJEXT_TEXT_YELLOW}${project_name}${PROJEXT_TEXT_RESET}\" Does not exist."
    return 1
  fi

  local proxy_project_path
  proxy_project_path="$(_project_get_project_path_by_name "$proxy_project_name")"
  local nginx_configs_dir
  nginx_configs_dir="$(_project_get_env_value "$proxy_project_name" "PROJECT_NGINX_CONFIGS_DIR")"

  declare -a project_tags=()
  _project_get_tags "$project_name" project_tags

  local output_file
  local project_domain
  # If this project has tags.
  if [ ${#project_tags[@]} -ne 0 ] && [ -z "${p["project_tag"]}" ]; then
    # Update php env for all tags.
    for project_tag in "${project_tags[@]}"; do
      project_domain="$(_project_get_env_value "$project_name" PROJECT_DOMAIN "$project_tag")"
      output_file="$proxy_project_path/$nginx_configs_dir/$project_domain.conf"
      p["project_tag"]="$project_tag"
      project_run_global_script "create_nginx_config" "$template" "$output_file" "$allow_overwriting"
      project_run_global_script "create_nginx_log_files" "$project_name" "$project_path" "$project_domain"
    done
    # Reset project tag to not mess things up.
    p["project_tag"]=""
  else
    # Update php env for the given tag or empty.
    project_domain="$(_project_get_env_value "$project_name" PROJECT_DOMAIN)"
    output_file="$proxy_project_path/$nginx_configs_dir/$project_domain.conf"
    project_run_global_script "create_nginx_config" "$template" "$output_file" "$allow_overwriting"
    project_run_global_script "create_nginx_log_files" "$project_name" "$project_path" "$project_domain"
  fi
}

_project_global_script_add_project_to_proxy() {
  local proxy_project_name="${1:-${PROJECT_PROXY_PROJECT_NAME:-proxy}}"
  local proxy_project_path
  proxy_project_path="$(_project_get_project_path_by_name "$proxy_project_name")"
  local path_in_proxy="${PROJECT_PATH_IN_PROXY_CONTAINER:-/srv/${PROJECT_DOMAIN}}"

  _project_run_script "$proxy_project_name" "$proxy_project_path" "add_volume" "$PROJECT_PATH" "$path_in_proxy"
  project_run_global_script "create_nginx_config_for_project" "$PROJECT_NAME" "$PROJECT_NGINX_TEMPLATE" "$proxy_project_name"

  _project_setup_project "$proxy_project_name"
  _project_run_script "$proxy_project_name" "$proxy_project_path" "update_docker_compose" "$PROJECT_PATH" "$path_in_proxy"
}

_project_global_script_create_nginx_log_files() {
  local project_name="$1"
  local project_path="$2"
  local project_domain="$3"
  local logs_dir
  logs_dir="$(_project_get_logs_dir "$project_name")"

  local access_log_filename="$project_path/$logs_dir/${project_domain}_access.log"
  if [ ! -f "$access_log_filename" ]; then
    touch "$access_log_filename"
  fi

  local error_log_filename="$project_path/$logs_dir/${project_domain}_error.log"
  if [ ! -f "$error_log_filename" ]; then
    touch "$error_log_filename"
  fi
}

_project_global_script_end() {
  sudo systemctl stop docker
}