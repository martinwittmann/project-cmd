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

# shellcheck disable=SC2120
_project_global_script_start() {
  is_dev="$1"

  if project_uses_docker; then
    if ! systemctl is-active --quiet docker; then
      sudo systemctl start docker
    fi

    local compose_file
    compose_file="$(project_get_docker_compose_path)"

  	declare -a env_files=()
  	_project_get_env_files "$PROJECT_NAME" "$PROJECT_TAG" env_files

		local compose_arguments=("--project-name" "$PROJECT_NAME")
		for env_file in "${env_files[@]}"; do
			compose_arguments+=("--env-file" "$env_file")
		done
		compose_arguments+=("-f" "$compose_file")

    # We always daemonize and remove orphans to not accumulate old containers.
    if ! docker compose "${compose_arguments[@]}" up -d --remove-orphans; then
      project_show_error "Error starting docker compose for project \"${TEXT_YELLOW}${PROJECT_NAME}${TEXT_RESET}\"."
      return 1
    fi
  else
    project_show_error "I don\'t know how to start project \"${TEXT_YELLOW}$PROJECT_NAME${TEXT_RESET}\" since it is not configured to use docker and no start script is specified."
    return 1
  fi

  if [ -n "$is_dev" ]; then
    dev_script="$(_project_get_env_value "$PROJECT_NAME" "PROJECT_DEV_SCRIPT" "$PROJECT_TAG" "vite")"
    vite_script_filename=$(_project_get_script_path "$PROJECT_PATH" "$dev_script")

    if [ -n "$PROJECT_URL" ]; then
      # Open the url in the background after 2s.
      # We do this to wait for the dev script to be up and running so that the
      # project can use it when opened in the browser.
      (
        sleep 2
        project_open_url "$PROJECT_URL"
      ) &
    fi

    if [ -n "$vite_script_filename" ]; then
      # Shift away the first argument defining that we'd like to execute the
      # dev script and only pass along the rest of the arguments.
      shift
      _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "$dev_script" "$@"
    else
      project_show_error "The dev script \"${TEXT_YELLOW}${dev_script}${TEXT_RESET}\" can't be found in this project."
      return 1
    fi
  elif [ -n "$PROJECT_URL" ]; then
    _project_print_url "$PROJECT_URL"
  fi
}

_project_global_script_stop() {
  if project_uses_docker; then
    local compose_file
    compose_file=$(project_get_docker_compose_path)

  	declare -a env_files=()
  	_project_get_env_files "$PROJECT_NAME" "$PROJECT_TAG" env_files

		local compose_arguments=("--project-name" "$PROJECT_NAME")
		for env_file in "${env_files[@]}"; do
			compose_arguments+=("--env-file" "$env_file")
		done
		compose_arguments+=("-f" "$compose_file")

    docker compose "${compose_arguments[@]}" down
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

  echo -e "Creating database dump at \"${TEXT_YELLOW}${short_name}${TEXT_RESET}\"..."
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
    project_show_error "Could not find sql dump: \"${TEXT_YELLOW}${dump_file}${TEXT_RESET}\"."
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
  readarray -t file_names < <(ls -lh "$dumps_path" | tail -n +2 | sort -r | awk '{print $9}')
  readarray -t file_sizes < <(ls -lh "$dumps_path" | tail -n +2 | sort -r | awk '{print $5}')

  local max_length
  max_length=$(_project_get_max_length_of_list "${file_names[@]}")

  for index in "${!file_names[@]}"; do
    local name="${file_names[index]}"
    local size="${file_sizes[index]}"
    local padding_length=$(($max_length - ${#name}))
    printf "%s%*s (%s)\n" "$name" $padding_length "" "$size"
  done
}

_project_global_script_psql() {
  local user="${1:-${PROJECT_DB_USER:-postgres}}"
  local database="${2:-${PROJECT_DB_NAME}}"
  shift 2
  docker exec -it --user "$user" "$PROJECT_DB_CONTAINER_NAME" psql -p "$PROJECT_DB_PORT" -d "$database" "$@"
}

_project_global_script_postgres_import_dump() {
  local dump_file="$1"
  local user="${2:-${PROJECT_DB_USER:-postgres}}"
  if [ ! -f "$dump_file" ]; then
    project_show_error "Could not find sql dump: \"${TEXT_YELLOW}${dump_file}${TEXT_RESET}\"."
    return 1
  fi

  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    cat "$dump_file" | docker exec -i --user "$user" "$PROJECT_DB_CONTAINER_NAME" psql -p "$PROJECT_DB_PORT" -d "$PROJECT_DB_NAME"
  else
    cat "$dump_file" | psql -d "$PROJECT_DB_NAME"
  fi 
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

_project_global_script_docker_containers_rebuild() {
  if project_uses_docker; then
    local container_name="${1:-app}"
    local compose_file
    compose_file="$(project_get_docker_compose_path)"
    docker compose --project-name "$PROJECT_NAME" -f "$compose_file" build "$container_name"
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
    project_show_error "Could not find file \"${TEXT_YELLOW}${filename}${TEXT_RESET}\" in this project."
    return 1
  fi

  if [ ! $? -eq 0 ]; then
    project_show_error "Could not find project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  local other_project_path
  other_project_path="$(_project_get_project_path_by_name "$project_name")"
  local filename_in_other_project="$other_project_path/$relative_filename"

  if [ ! -f "$filename_in_other_project" ] && [ ! -d "$filename_in_other_project" ]; then
    project_show_error "Could not find file \"${TEXT_YELLOW}${filename_in_other_project}${TEXT_RESET}\" in project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
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

  else
    local hash_salt
    hash_salt="$(project_run_global_script drush php:eval 'echo \Drupal\Component\Utility\Crypt::randomBytesBase64(55) . "\n";')"
    sed -i "s/^PROJECT_DRUPAL_HASH_SALT.*/PROJECT_DRUPAL_HASH_SALT=$hash_salt/" .env
    project_show_success "Set PROJECT_DRUPAL_HASH_SALT to ${hash_salt}"
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
    project_show_error "The output file \"${TEXT_YELLOW}${output_file}${TEXT_RESET}\" already exists.\nSet the third argument of the create_nginx_config global script to 1 to allow overwriting it."
    return 1
  fi

  local project_path
  project_path="$(_project_get_project_path_by_name "$project_name")"
  # Project domain needs to be retrieved via _project_get_env_value to respect
  # project tags.
  local project_domain
  project_domain="$(_project_get_env_value "$project_name" PROJECT_DOMAIN)"

  if [ -z "$project_domain" ]; then
    project_show_error "No project domain set!"
    return 1
  fi

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
    project_show_success "Created nginx configuration \"${TEXT_YELLOW}${output_file}${TEXT_RESET}\"."
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
    project_show_error "Project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" Does not exist."
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

  _project_run_script "$proxy_project_name" "$proxy_project_path" "volumes_add" "$PROJECT_PATH" "$path_in_proxy" "1"
  project_run_global_script "create_nginx_config_for_project" "$PROJECT_NAME" "$PROJECT_NGINX_TEMPLATE" "$proxy_project_name" "1"

  _project_setup_project "$proxy_project_name"
  _project_run_script "$proxy_project_name" "$proxy_project_path" "docker_compose_update"
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

_project_global_script_create_passphrase() {
  local length=${1:-24}
  # Try to use openssl and fall back to urandom
  if type openssl &> /dev/null; then
    openssl rand -base64 $((length * 3/4)) | tr -d '\n' | tr -d '='
  else
    tr -dc '[:alnum:]' < /dev/urandom | head -c $length
  fi
}

_project_global_script_create_backup_passphrase() {
  local project_name="${1:-${PROJECT_NAME}}"
  local project_tag="${2:-${PROJECT_TAG}}"
  local overwrite="$3"

  local passphrase
  passphrase=$(project_run_global_script create_passphrase)

  declare -a env_files=()
  _project_get_env_files "$project_name" "$project_tag" env_files

  local current_passphrase
  for env_file in "${env_files[@]}"; do
    current_passphrase=$(_project_get_env_value "$project_name" PROJECT_BACKUP_PASSPHRASE)

    if [ -z "$current_passphrase" ] || [ -n "$overwrite" ]; then
      # We use the given overwrite value, but never add the variable if it does not exist.
      # Env files should contain all necessary variables, even if values are empty.
      project_set_env_file_variable "$env_file" "PROJECT_BACKUP_PASSPHRASE" "$passphrase" "$overwrite" ""
    fi
  done
}

_project_global_script_set_up_backups() {
  local type="$1"
  local project_name="${2:-${PROJECT_NAME}}"

  if [ "$type" != "borg" ]; then
    project_show_error "Only borg backup via ssh is supported at the moment."
    return 1
  fi

  # Make sure a passphrase is set.
  project_run_global_script create_backup_passphrase

  local ssh_host
  local ssh_port
  local ssh_user
  local ssh_password
  local borg_passphrase
  local backup_target_path

  if [ "$project_name" == "$PROJECT_NAME" ]; then
    ssh_host="$PROJECT_BACKUP_SSH_HOST"
    ssh_port="${PROJECT_BACKUP_SSH_PORT:-22}"
    ssh_user="$PROJECT_BACKUP_SSH_USER"
    ssh_password="$PROJECT_BACKUP_SSH_PASSWORD"
    borg_passphrase="$PROJECT_BACKUP_PASSPHRASE"
    backup_target_path="$PROJECT_BACKUP_TARGET_PATH"
  else
    ssh_host=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_HOST)
    ssh_port=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_PORT "" "22")
    ssh_user=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_USER)
    ssh_password=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_PASSWORD)
    borg_passphrase=$(_project_get_env_value "$project_name" PROJECT_BACKUP_PASSPHRASE)
    backup_target_path=$(_project_get_env_value "$project_name" PROJECT_BACKUP_TARGET_PATH)
  fi

  local public_key_file
  if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    public_key_file="$HOME/.ssh/id_rsa.pub"
  elif [ -f "$HOME/.ssh/id_dsa.pub" ]; then
    public_key_file="$HOME/.ssh/id_dsa.pub"
  else
    project_show_error "Could not detect a public key file in \"${TEXT_YELLOW}${HOME}${TEXT_RESET}\"."
    return 1
  fi

  # Allow ssh connections to the storage box.
  if ! ssh "${ssh_user}@${ssh_host}" -oBatchMode=yes -p "$ssh_port" "exit" 2> /dev/null; then
    echo -e "Trying to add public key \"${TEXT_YELLOW}${public_key_file}${TEXT_RESET}\" to authorized_keys on \"${TEXT_YELLOW}${ssh_host}${TEXT_RESET}\"."
    # We're doing it this way to not have the ssh password be written to bash history.
    (
      # Install the public key on the storagebox and add it to known_hosts by using StrictHostKeyChecking=accept-new.
      cat "$public_key_file" | SSHPASS="$ssh_password" sshpass -e ssh -o StrictHostKeyChecking=accept-new "$ssh_user@$ssh_host" -p "$ssh_port" install-ssh-key
    )

    if [ $? -ne 0 ]; then
      project_show_error "Error adding public key to  \"${TEXT_YELLOW}${ssh_host}${TEXT_RESET}\"."
      return 1
    fi
    project_show_success "Set up ssh connection + public key authentication to \"${TEXT_YELLOW}${ssh_host}${TEXT_RESET}\"."
  else
    project_show_success "Ssh connection \"${TEXT_YELLOW}${ssh_host}${TEXT_RESET}\" is already working."
  fi

  # Make sure the backup_target_path exists, so borg can initialize a repository.
  (
    SSHPASS="$ssh_password" sshpass -e ssh "$ssh_user@$ssh_host" -p "$ssh_port" mkdir -p "$backup_target_path"
  )

  local repository_url
  repository_url=$(_project_get_borg_backup_repository "$project_name")

  # Initialize borg repository if it does not exist.
  # Note that we assume that the ssh session drops the user into the correct directory ($backup_target_path) on the server.
  echo -e "Setting up repository \"${TEXT_YELLOW}${repository_url}${TEXT_RESET}\"."
  (
    BORG_PASSPHRASE="$borg_passphrase" borg init --encryption=repokey "${repository_url}"
  )
  if [ $? -eq 0 ]; then
    project_show_success "Backup repository set up."
  fi
}

# By default all files in the project path will be backed up.
# To include or exclude paths from backing up, create the file
# .project/backup.patterns and add inclusion/exclusion patterns.
# See --patterns-from option in https://borgbackup.readthedocs.io/en/stable/usage/create.html
# See https://borgbackup.readthedocs.io/en/stable/usage/help.html#borg-patterns

# To dynamically / programmatically include or exclude files additionally
# to the ones defined in .project/backup.patterns append arguments to the
# _project_global_script_create_backup_for_project below.
# Each argument after project name will be added to borg create as
# --pattern $argument.
# Example to include a database dump and exclude a cache directory.
# _project_global_script_create_backup_for_project "$PROJECT_NAME" \
#  "+.project/dumps/YYYY-mm-dd--HH-MM-SS.sql" \
#  "-build/cache-*" \
_project_global_script_create_backup_for_project() {
  local project_name="${1:-${PROJECT_NAME}}"
  local project_path=""
  shift
  # We consider all arguments after the project name to be include/exclude
  # patterns which will be added before --patterns-from.
  local extra_patterns=("$@")

  if [ -z "$project_name" ] || ! project_path=$(_project_get_project_path_by_name "$project_name"); then
    project_show_error "Could not find project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  if [ ! -d "$project_path" ]; then
    project_show_error "Cannot create backup for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" since the project path \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\" does not exist."
    return 1
  fi

  if ! repository=$(_project_get_borg_backup_repository "$project_name"); then
    project_show_error "Error getting borg backup repository url for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  local backup_patterns_file="$project_path/.project/backup.patterns"
  archive_name="$(date +%F--%H-%M-%S)"

  local borg_arguments=()
  for pattern in "${extra_patterns[@]}"; do
    borg_arguments+=(--pattern "$pattern")
  done

  if [ -f "$backup_patterns_file" ]; then
    borg_arguments+=("--patterns-from" "$backup_patterns_file")
  fi

  borg_arguments+=("${repository}::${archive_name}" ".")

  (
    cd "$project_path"
    BORG_PASSPHRASE=$(_project_get_borg_backup_passphrase "$project_name") borg create "${borg_arguments[@]}"
  )
}

_project_global_script_restore_project_from_backup() {
  local project_name="${1:-${PROJECT_NAME}}"
  local archive_name="$2"
  local dont_ask="$3"
  local project_path=""
  shift 3
  # We consider all arguments after the project name to be include/exclude
  # patterns which will be added before --patterns-from.
  local extra_patterns=("$@")

  if [ -z "$project_name" ] || ! project_path=$(_project_get_project_path_by_name "$project_name"); then
    project_show_error "Could not find project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  if [ ! -d "$project_path" ]; then
    project_show_error "Cannot restore \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" from backup since the project path \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\" does not exist."
    return 1
  fi

  if ! repository=$(_project_get_borg_backup_repository "$project_name"); then
    project_show_error "Error getting borg backup repository url for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  if [ -z "$archive_name" ]; then
    archive_name=$(_project_get_last_borg_backup_archive "$project_name")
  fi

  if [ -z "$archive_name" ]; then
    project_show_error "No backup archive name was given and the repository does not contain any archives for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  local borg_arguments=()
  if [ -z "$dont_ask" ]; then
    read -p "$(echo -e "${p["_status_danger"]} Do you really want to restore \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" to the archived state from \"${TEXT_YELLOW}${archive_name}${TEXT_RESET}\"? (y/N): ")" answer

    case "$answer" in
      [yY][eE][sS]|[yY]) 
      do_restore=true
      ;;
      *) 
        project_show_warning "Aborted."
        return 1
      ;;
    esac
	
  fi

  for pattern in "${extra_patterns[@]}"; do
    borg_arguments+=(--pattern "$pattern")
  done

  local backup_patterns_file="$project_path/.project/backup_restore.patterns"
  if [ -f "$backup_patterns_file" ]; then
    borg_arguments+=("--patterns-from" "$backup_patterns_file")
  fi
  echo "restore patterns: $backup_patterns_file"

  borg_arguments+=("${repository}::${archive_name}")

  echo -e "Restoring data from backup archive \"${TEXT_YELLOW}${archive_name}${TEXT_RESET}\"..."

  (
    cd "$project_path"
    BORG_PASSPHRASE=$(_project_get_borg_backup_passphrase "$project_name") borg extract "${borg_arguments[@]}"
  )

  if [ $? -eq 0 ]; then
    project_show_success "Restore complete."
  else
    project_show_error "Please check what went wrong during restoring."
  fi
}

_project_global_script_list_backups_for_project() {
  local project_name="${1:-${PROJECT_NAME}}"
  local project_path=""

  if [ -z "$project_name" ] || ! project_path=$(_project_get_project_path_by_name "$project_name"); then
    project_show_error "Could not find project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  if [ ! -d "$project_path" ]; then
    project_show_error "Cannot create backup for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" since the project path \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\" does not exist."
    return 1
  fi

  if ! repository=$(_project_get_borg_backup_repository "$project_name"); then
    project_show_error "Error getting borg backup repository url for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  (
    BORG_PASSPHRASE=$(_project_get_borg_backup_passphrase "$project_name") borg list "${repository}" "$project_path"
  )
}

_project_get_last_borg_backup_archive() {
  local project_name="${1:-${PROJECT_NAME}}"
  _project_global_script_list_backups_for_project "$project_name" | sort -r | head -n 1 | awk '{print $1}'
}


_project_global_script_rotate_backups_for_project() {
  local project_name="${1:-${PROJECT_NAME}}"

  if [ -z "$project_name" ]; then
    project_show_error "Could not find project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  if ! repository=$(_project_get_borg_backup_repository "$project_name"); then
    project_show_error "Error getting borg backup repository url for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  local keep_arguments=()

  local keep_daily
  local keep_weekly
  local keep_monthly
  local keep_yearly
  # We don't use default values to allow projects to define their retention
  # policies as needed.
  keep_daily=$(_project_get_env_value "$project_name" PROJECT_BACKUP_KEEP_DAILY)
  if [ -n "$keep_daily" ] && _project_is_int "$keep_daily"; then
    keep_arguments+=("--keep-daily" "$keep_daily")
  fi

  keep_weekly=$(_project_get_env_value "$project_name" PROJECT_BACKUP_KEEP_WEEKLY)
  if [ -n "$keep_weekly" ] && _project_is_int "$keep_weekly"; then
    keep_arguments+=("--keep-weekly" "$keep_weekly")
  fi

  keep_monthly=$(_project_get_env_value "$project_name" PROJECT_BACKUP_KEEP_MONTHLY)
  if [ -n "$keep_monthly" ] && _project_is_int "$keep_monthly"; then
    keep_arguments+=("--keep-monthly" "$keep_monthly")
  fi

  keep_yearly=$(_project_get_env_value "$project_name" PROJECT_BACKUP_KEEP_YEARLY)
  if [ -n "$keep_yearly" ] && _project_is_int "$keep_yearly"; then
    keep_arguments+=("--keep-yearly" "$keep_yearly")
  fi

  if [ ${#keep_arguments[@]} -eq 0 ]; then
    project_show_error "No retention / pruning parameters set for this project.\n        Exiting to prevent losing backups."
    return 1
  fi

  local passphrase
  passphrase=$(_project_get_borg_backup_passphrase "$project_name")
  (
    BORG_PASSPHRASE="$passphrase" borg prune "${keep_arguments[@]}" --list --dry-run "${repository}"
    BORG_PASSPHRASE="$passphrase" borg compact "${repository}"
  )
}

_project_global_script_ssh_into_backup() {
  local project_name="${1:-${PROJECT_NAME}}"
  local ssh_host
  local ssh_port
  local ssh_user
  local ssh_password

  if [ "$project_name" == "$PROJECT_NAME" ]; then
    ssh_host="$PROJECT_BACKUP_SSH_HOST"
    ssh_port="${PROJECT_BACKUP_SSH_PORT:-22}"
    ssh_user="$PROJECT_BACKUP_SSH_USER"
    ssh_password="$PROJECT_BACKUP_SSH_PASSWORD"
  else
    ssh_host=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_HOST)
    ssh_port=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_PORT "" "22")
    ssh_user=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_USER)
    ssh_password=$(_project_get_env_value "$project_name" PROJECT_BACKUP_SSH_PASSWORD)
  fi

  (
    SSHPASS="$ssh_password" sshpass -e ssh "$ssh_user@$ssh_host" -p "$ssh_port"
  )
}

_project_global_script_mount_project_backup() {
  local project_name="${1:-${PROJECT_NAME}}"
  local archive_name="$2"
  local mount_point="$3"

  # Try to get the server's default backup mount point if configured.
  if [ -z "$mount_point" ]; then
    local base_mount_point
    base_mount_point="$(_project_get_env_value "server_setup" PROJECT_GLOBAL_BACKUPS_MOUNT_POINT)"

    if [ -n "$base_mount_point" ]; then
      mount_point="$base_mount_point/$project_name"
      # If we use the servers default mount point create it if necessary.
      if [ ! -d "$mount_point" ]; then
        mkdir "$mount_point" -p
      fi
    fi
  fi

  if [ ! -d "$mount_point" ]; then
    project_show_error "The given mount point \"${TEXT_YELLOW}${mount_point}${TEXT_RESET}\" does not exist."
    return 1
  fi

  # The flag -A lists everything except '.' and '..'.
  if [ -n "$(ls -A "$mount_point")" ]; then
    project_show_error "The given mount point \"${TEXT_YELLOW}${mount_point}${TEXT_RESET}\" is not empty."
    return 1
  fi

  if [ -z "$project_name" ] || ! project_exists "$project_name"; then
    project_show_error "Could not find project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  if ! repository=$(_project_get_borg_backup_repository "$project_name"); then
    project_show_error "Error getting borg backup repository url for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  if [ -z "$archive_name" ]; then
    archive_name=$(_project_get_last_borg_backup_archive "$project_name")
  fi

  if [ -z "$archive_name" ]; then
    project_show_error "No backup archive name was given and the repository does not contain any archives for project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  local passphrase
  passphrase=$(_project_get_borg_backup_passphrase "$project_name")
  (
    BORG_PASSPHRASE="$passphrase" borg mount "${repository}::${archive_name}" "$mount_point"
  )
}

_project_global_script_umount_project_backup() {
  local mount_point="$1"

  # Try to get the server's default backup mount point if configured.
  if [ -z "$mount_point" ]; then
    local base_mount_point
    base_mount_point="$(_project_get_env_value "server_setup" PROJECT_GLOBAL_BACKUPS_MOUNT_POINT)"

    if [ -n "$base_mount_point" ]; then
      mount_point="$base_mount_point/$project_name"
    fi
  fi

  if [ ! -d "$mount_point" ]; then
    project_show_error "The given mount point \"${TEXT_YELLOW}${mount_point}${TEXT_RESET}\" does not exist."
    return 1
  fi

  local passphrase
  passphrase=$(_project_get_borg_backup_passphrase "$project_name")
  (
    BORG_PASSPHRASE="$passphrase" borg umount "$mount_point"
  )
}
