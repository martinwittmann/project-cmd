#!/bin/bash

_project_populate_projects_array() {
  # Note that we can't use double quotes in the for loop as this breaks it for
  # some reason.
  for symlink in ${p["projects_path"]}/*; do
    if [ -L "$symlink" ]; then
      local project_path
      project_path=$(readlink -f "$symlink")
      if [ $? -ne 0 ]; then
        basename "$symlink"
        echo "Could not read $symlink"
        return 1
      fi
      PROJECTS["$project_path"]=$(basename "$symlink")
    fi
  done
}

_project_get_available_commands() {
  local -n result=$1
  local command
  for command in "${p["_script_path"]}"/commands/*.sh; do
    if [ -f "$command" ]; then
      result+=("$(basename "$command"|sed -e 's/\.sh$//')")
    fi
  done
}

_project_get_project_path_by_name() {
  project_name="$1"
  local item_name

  for item_path in "${!PROJECTS[@]}"; do
    local item_name="${PROJECTS["$item_path"]}"
    if [ "$project_name" == "$item_name" ]; then
      echo "$item_path"
      return 0
    fi
  done

  return 1
}

_project_get_project_path() {
  local current_path="$1"
  local show_errors="${2:-1}"

  if [ -z "$current_path" ]; then
    current_path=$(pwd)
  fi

  if [[ -v PROJECTS["$current_path"] ]]; then
    echo "$current_path"
  elif [ "$current_path" == "/" ] && [ "$show_errors" == "1" ]; then
    return 1
  else
    current_path=$(realpath "$current_path/..")
    _project_get_project_path "$current_path"
  fi
}

_project_get_project_name() {
  local project_path="$1"
  local show_errors="${2:-1}"

  if [ -z "$project_path" ]; then
    project_path=$(_project_get_project_path)
  fi

  if [[ -v PROJECTS["$project_path"] ]]; then
    echo "${PROJECTS["$project_path"]}"
  elif [ "$show_errors" == "1" ]; then
    project_show_error "Project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" not found."
    return 1
  fi
}

# All messages are written to stderr to not pollute stdout.
project_show_error() {
  echo -e "${p["_status_error"]} $1" >&2
}

project_show_warning() {
  echo -e "${p["_status_warning"]} $1" >&2
}

project_show_success() {
  echo -e "${p["_status_success"]} $1" >&2
}

project_show_message() {
  echo -e "$1" >&2
}

_project_get_scripts_path() {
  local project_path="$1"
  if [ -z "$project_path" ]; then
    project_path="$(_project_get_project_path)"
  fi

  echo "$project_path/.project/scripts"
}

_project_get_script_path() {
  local project_path="$1"
  local script_name="$2"
  echo "$project_path/.project/scripts/$script_name.sh"
}

_project_load_script() {
  local project_name="$1"
  local script_name="$2"
  local show_errors="${3:-0}"
  local function_name="_project_${project_name}_run_$script_name"
  local project_path
  project_path="$(_project_get_project_path_by_name "$project_name")"
  local scripts_path
  scripts_path="$(_project_get_scripts_path "$project_path")"
  local script_filename="$scripts_path/$script_name.sh"

  if [ -f "$script_filename" ]; then
    source "$script_filename"
  fi

  if [ "$(type -t "$function_name")" != "function" ]; then
    if [ "$show_errors" == "1" ]; then
      project_show_warning "The script \"${TEXT_YELLOW}${script_name}${TEXT_RESET}\" does not exist in project ${TEXT_YELLOW}${project_name}${TEXT_RESET}."
    fi
    return 1
  fi
}

_project_run_script() {
  local project_name="$1"
  local project_path="$2"
  local script_name="$3"
  shift 3
  local script_filename
  script_filename="$(_project_get_script_path "$project_path" "$script_name")"

  # We need to source the global scripts file to make sure these functions are
  # available for project script files.
  local global_scripts="${p["_script_path"]}/_global-scripts.sh"
  source "$global_scripts"

  if [ -f "$script_filename" ]; then
    # We need to source the script file to make all our variables and commands /
    # functions available to the script.

    if [ "$project_name" == "$PROJECT_NAME" ]; then
      source "$script_filename"
    else
      echo "$(_project_setup_project "$project_name" && source "$script_filename")"
    fi
  else
    project_show_error "$script_filename The script \"${TEXT_YELLOW}${script_name}${TEXT_RESET}\" does not exist in project ${TEXT_YELLOW}${project_name}${TEXT_RESET}."
  fi
}

_project_get_project_names() {
  for item_path in "${!PROJECTS[@]}"; do
    echo "${PROJECTS["$item_path"]}"
  done
}

_project_get_project_status() {
  local project_name="$1"
  local project_path="$2"
  local name_padding=$((10 - ${#project_name}))
  local script_filename="$(_project_get_script_path "$project_path" "status")"
  local project_status

  if [ -f "$script_filename" ]; then
    project_status="$(_project_run_script "$project_name" "$project_path" "status" "short")"
  else
    project_status="${TEXT_GRAY}unknown${TEXT_RESET}"
  fi

  name_padding="$(printf "%${name_padding}s")"
  local path_padding="$((60 - ${#project_path}))"
  path_padding="$(printf "%${path_padding}s")"

  echo -e " ${TEXT_YELLOW}${project_name}${name_padding}${TEXT_RESET} $project_path${path_padding}$project_status"
}

project_add_project() {
  local project_name="$1"
  local quiet="${2:-0}"

  if [ -z "$project_name" ]; then
    project_show_error "You need to provide a project name."
    return 1
  fi

  local project_path="$2"
  if [ -z "$project_path" ]; then
    project_show_error "You need to provide a project path."
    return 1
  fi
  project_path="$(realpath "$project_path")"

  if [ ! -d "$project_path" ]; then
    project_show_error "The project path \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\" does not exist."
    return 1
  fi
  local symlink="${p["projects_path"]}/$project_name"
  sudo ln -s "$project_path" "$symlink"

  if [ "$quiet" == "0" ]; then
    project_show_success "Added project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
  fi
}

project_create_from_template() {
  local project_template="$1"
  local project_name="$2"
  local project_path="$3"

  local template_path="${p["_script_path"]}/project-templates/$project_template"
  if [ -z "$project_template" ] || [ ! -d "$template_path" ]; then
    project_show_error "Could not find project template \"${TEXT_YELLOW}${project_template}${TEXT_RESET}\"."
    return 1
  fi

  if [ -z "$project_name" ]; then
    project_show_error "You need to provide a name for this project."
    return 1
  fi

  if project_exists "$project_name"; then
    project_show_error "A project with the name \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" already exists."
    return 1
  fi

  if [ ! -d "$project_path" ] && ! mkdir -p "$project_path"; then
    project_show_error "Could not create project directory \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\"."
    return 1
  fi

  if ! rsync -a "$template_path/" "$project_path"; then
    project_show_error "Could not copy project template to \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\"."
    return 1
  fi

  project_path="$(realpath "$project_path")"

  # Set project name in .env
  sed -i "s/^PROJECT_NAME=.*/PROJECT_NAME=$project_name/" "$project_path/.env"

  if ! project_add_project "$project_name" "$project_path"; then
    project_show_error "Could not add project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."
    return 1
  fi

  # Make project-cmd aware of the new project.
  _project_populate_projects_array
  local old_pwd
  old_pwd="$(pwd)"

  cd "$project_path"
  local init_script="$project_path/.project/scripts/_init_project.sh"
  if [ -f "$init_script" ]; then
    _project_run_script "$project_name" "$project_path" "_init_project"
  fi

  project_show_success "Created project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\"."

  cd "$old_pwd"
}

# shellcheck disable=SC2120
project_get_docker_compose_path() {
  local project_name="${1:-$PROJECT_NAME}"
  local project_path
  project_path="$(_project_get_project_path_by_name "$project_name")"
  local project_env
  project_env="$(_project_get_env_value "$project_name" "PROJECT_ENV")"
  echo "${project_path}/docker-compose.${project_env}.yml"
}

project_uses_docker() {
  if [ "$PROJECT_USE_DOCKER" == "1" ]; then
    # Result code 0 is a success in bash.
    return 0
  else
    return 1
  fi
}

# Only call this in a sub-shell since this will overwrite all project variables
# by calling project_setup_project
_project_get_project_status_via_docker_compose() {
  local project_name="${1:-$PROJECT_NAME}"

  # Output format can be "services" or "summary"
  local output_format="${2:-summary}"
  local compose_file
  compose_file="$(project_get_docker_compose_path)"
  local status
  status="$(docker compose -f "$compose_file" ps --format '{{.Name}} {{.Status}}')"

  local project_status="down"
  local all_services_up=true

  if [ -z "$status" ]; then
    if [[ "$output_format" == "services" ]]; then
      echo -n "All services are "
    fi
    _project_status_output "down"
    return 0
  fi

  while IFS= read -r line; do
    local container_name
    container_name="$(echo "$line" | awk '{print $1}')"
    local container_status
    container_status="$(echo "$line" | tr '[:upper:]' '[:lower:]' | awk '{print $2}')"


    if [ "$container_status" == "up" ]; then
      if [ "$project_status" == "down" ]; then
        project_status="partial"
      fi
    else
      all_services_up=false
    fi

    if [[ "$output_format" == "services" ]]; then
      local spaces=$((10 - ${#container_name}))
      spaces="$(printf "%${spaces}s")"
      echo -n " $container_name:$spaces"
      _project_status_output "$container_status"
    fi
  done <<< "$status"

  if [ $all_services_up ]; then
    project_status="up"
  fi

  if [[ "$output_format" == "summary" ]]; then
    echo -n "All services are "
    _project_status_output "$project_status"
  elif [[ "$output_format" == "short" ]]; then
    _project_status_output "$project_status"
  fi
}

_project_status_output() {
  local status="$1"
  if [ "$status" == "up" ]; then
    echo -e "${TEXT_GREEN}${status}${TEXT_RESET}"
  elif [ "$status" == "partial" ]; then
    echo -e "${TEXT_GREEN}${status}${TEXT_RESET}"
  else
    echo -e "${TEXT_RED}${status}${TEXT_RESET}"
  fi
}

_project_print_url() {
  local url="$1"
  echo -en "\nProject ${TEXT_YELLOW}$PROJECT_NAME${TEXT_RESET} available at: "
  echo -e "${TEXT_CYAN}\e]8;;$url\a$url\e]8;;\a${TEXT_RESET}"
  echo ""
}

project_exists() {
  local project_name="$1"

  if [ -z "$project_name" ]; then
    return 1
  fi

  local project_path
  project_path="$(_project_get_project_path_by_name "$project_name")"

  if [ $? -ne 0 ] || [ -z "$project_path" ]; then
    return 1
  else
    return 0
  fi
}

_project_assert_project_exists() {
  local project_name="$1"
  local project_path="$2"
  if [ -z $project_path ]; then
    project_path="$(_project_get_project_path_by_name "$project_name")"

    if [ $? -ne 0 ]; then
      return 1
    fi
  fi

  if [ -z "$project_name" ] || [ -z "$project_path" ] || [ ! -d "$project_path" ]; then
    project_show_error "Project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" not found."
    return 1
  fi

  return 0
}

_project_assert_env_var() {
  local env_var="$1"
  local value="${!env_var}"
  if [ -z "$value" ]; then
    project_show_error "The env variable \"\$${env_var}\" needs to be set for this command."
  fi
}

project_start_docker() {
  local force_start="${1:-0}"
  if project_uses_docker || [ "$force_start" -eq 1 ]; then
    if ! systemctl is-active --quiet docker; then
      project_show_message "Docker is not running. Starting docker service..."
      sudo systemctl start docker
    fi
  else
    project_show_error "This project is not configured to use docker."
  fi
}

project_is_production() {
  if [ "$PROJECT_ENV" == "live" ] || [ "$PROJECT_ENV" == "production" ] || [ "$PROJECT_ENV" == "prod" ]; then
    return 0
  else
    return 1
  fi
}

project_build_docker_images() {
  local dirnames="$1"
  if [ -z "$dirnames" ]; then
    project_show_error "You need to specify directory names, separated by ';' for which docker images will be built."
    return 1
  fi
  local env="${2:-prod}"
  local basepath
  basepath="${3:-${p["_script_path"]}/docker/${dirname}}"

  if [ ! -d "$basepath" ]; then
    project_show_error "Directory \"${TEXT_YELLOW}${basepath}${TEXT_RESET}\" not found."
    return 1
  fi

  # For each directory in ./docker we build the corresponding docker container,
  # if a Dockerfile exists.
  project_start_docker 1

  IFS=';'
  for dirname in $dirnames; do
    project_build_global_docker_image "$dirname" "$env" "$basepath"
  done
  unset IFS
}
project_build_global_docker_image() {
  project_start_docker 1
  local dirname="$1"
  local basepath="${2:-${p["_script_path"]}/docker/${dirname}}"
  local env="${3:-prod}"
  local image_name_prefix="${4}"

  local fullpath="$basepath/$dirname"

  if [ ! -d "$basepath" ]; then
    project_show_error "Directory \"${TEXT_YELLOW}${basepath}${TEXT_RESET}\" not found. Skipping."
    echo ""
    exit 1
  fi

  if [ ! -d "$fullpath" ]; then
    project_show_error "Directory \"${TEXT_YELLOW}${fullpath}${TEXT_RESET}\" not found. Skipping."
    echo ""
    exit 1
  fi

  local image_name="${image_name_prefix}$dirname"
  if [ -n "$env" ]; then
    image_name="${image_name}:$env"
  fi

  project_show_message "Building image \"${TEXT_YELLOW}${image_name}${TEXT_RESET}\"..."
  docker build --build-arg APP_ENV="$env" -t "$image_name" "$fullpath"
  project_show_success "Done."
  echo ""
}

project_check_jinja2_availability() {
  # Since the original j2cli seems to by abandoned and its documentation refers
  # to https://github.com/mattrobenolt/jinja2-cli - we use this.

  if [ "$(type -t jinja2)" != "file" ]; then
    project_show_error "Jinja2 templating needs to be installed for templating to work in project-cmd.\n
    This is based on python 3 and can be installed via pip.
    On debian-based systems you can install it with 'apt-get update && apt-get install python3-pip' and\n
    'pip install jinja2-cli'.
    "
  fi
}

project_get_template_filename() {
  local template_arg="$1"
  # Extract part before the first ':'.
  local other_project_name="${template_arg%%:*}"

  # Remove the everything up until the first ':' from the original string.
  template_file="${template_arg#*:}"

  if [ -z "$other_project_name" ] || [ -z "$template_file" ]; then
    project_show_error "Invalid template argument \"${TEXT_YELLOW}${template_arg}${TEXT_RESET}\".\nPlease use the format \"${TEXT_YELLOW}${template_argument_format}${TEXT_RESET}\" and make sure the project and the corresponding path ([project_name]/.project/templates/[template]/path) exists."
    return 1
  fi

  # Resolve the template file
  local other_project_path
  other_project_path="$(_project_get_project_path_by_name "$other_project_name")"

  # Add the extension if it wasn't added already.
  if [[ "$template_file" != *".jinja" ]]; then
    template_file="${template_file}.jinja"
  fi
  local templates_path
  templates_path="$(realpath "$other_project_path/.project/templates")"

  echo "$templates_path/$template_file"
}

project_render_template() {
  local template_arg="$1"
  shift

  local template_argument_format="[project_name]:[path]/[to]/[template]"

  if [ -z "$template_arg" ]; then
    project_show_error -e "${p["_status_error"]} You need to specify a template in the form \"${TEXT_YELLOW}${template_argument_format}${TEXT_RESET}\" as first argument."
    return 1;
  fi

  local template_file
  template_file="$(project_get_template_filename "$template_arg")"

  if [ ! -f "$template_file" ]; then
    project_show_error "Cannot find template \"${TEXT_YELLOW}${template_file}${TEXT_RESET}\"."
    return 1
  fi

  # Create an options string with all given arguments as variables to pass to
  # jinja2. We're using strict to make jinja throw errors for undefined variables
  # that do not use the default filter. This allows us to know if any variables
  # without default values (=required variables) are missing.
  local jinja_arguments=()
  while [[ $# -gt 0 ]]; do
    local key="$1"
    local value="$2"

    if [ -z "$key" ]; then
      project_show_error "You need to provide arguments in sets of 2 for key and value. There is an empty key arguments."
      return 1
    fi

    if [ -z "$value" ]; then
      project_show_warning "Empty value for key \"${TEXT_YELLOW}${key}${TEXT_RESET}\"."
    fi
    jinja_arguments+=('-D')
    jinja_arguments+=("$key=$value")
    shift 2  # Shift to the next pair
  done

  (
    cd "$templates_path" || return 1
    jinja2 --strict "$template_file" "${jinja_arguments[@]}"
  )
}

_project_update_php_env() {
  local project_name="${1:-$PROJECT_NAME}"

  declare -a project_tags=()
  _project_get_tags "$project_name" project_tags


  # If this project has tags.
  if [ ${#project_tags[@]} -ne 0 ] && [ -z "${p["project_tag"]}" ]; then
    # Update php env for all tags.
    for project_tag in "${project_tags[@]}"; do
      _project_update_php_env_for_tag "$project_name" "$project_tag"
    done
  else
    # Update php env for the given tag or empty.
    _project_update_php_env_for_tag "$project_name" "${p["project_tag"]}"
  fi
}

_project_get_env_value() {
  local project_name="$1"
  local variable_name="$2"
  local project_tag="${3:-${p["project_tag"]}}"
  local default_value="$4"

  local project_path
  project_path=$(_project_get_project_path_by_name "$project_name")
  _project_assert_project_exists "$project_name" "$project_path"

  if [ -z "$variable_name" ]; then
      project_show_error "You need to provide a variable name as second argument."
      return 1
  fi

  declare -a env_files=()
  _project_get_env_files "$project_name" "$project_tag" env_files

  declare -a shdotenv_arguments=()
  for env_file in "${env_files[@]}"; do
    shdotenv_arguments+=('-e')
    shdotenv_arguments+=("$env_file")
  done

  shdotenv_arguments+=('--overload')
  shdotenv_arguments+=('--grep')
  shdotenv_arguments+=("$variable_name")
  shdotenv_arguments+=('-f')
  shdotenv_arguments+=('value')

  local value
  value="$("${p["_script_path"]}/lib/shdotenv/shdotenv" "${shdotenv_arguments[@]}")"

  # Remove starting and trailing quotes.
  value="${value#\"}"
  value="${value%\"}"

  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default_value"
  fi
}

_project_get_env_files() {
  local project_name="$1"
  local project_tag="$2"
  local -n result=$3
  local project_path
  project_path="$(_project_get_project_path_by_name "$project_name")"
  _project_assert_project_exists "$project_name" "$project_path"

  result+=("$project_path/.env")

  if [ -n "$project_tag" ] && [ -f "$project_path/.env.$project_tag" ]; then
    result+=("$project_path/.env.$project_tag")
  fi

  type -t result
}

_project_update_php_env_for_tag() {
  local project_name="$1"
  local project_tag="$2"
  local project_path
  project_path="$(_project_get_project_path_by_name "$project_name")"

  declare -a env_files=()
  _project_get_env_files "$project_name" "$project_tag" env_files

  if [ -z "$project_tag" ]; then
    output_file="$project_path/env.php"
  else
    output_file="$project_path/env.${project_tag}.php"
  fi

  _project_get_php_env_for_files "${env_files[@]}" > "$output_file"
}

# Each argument is treated as an env file and the output is written to stdout.
_project_get_php_env_for_files() {
  if [ "$#" -eq 0 ]; then
    project_show_error "_project_get_php_env_for_files: You need to provide at least one env file as argument."
  fi

  declare -a shdotenv_arguments=()
  for env_file in "$@"; do
    shdotenv_arguments+=('-e')
    shdotenv_arguments+=("$env_file")
  done

  shdotenv_arguments+=('--overload')
  shdotenv_arguments+=('-f')
  shdotenv_arguments+=('php')

  local output
  output="$("${p["_script_path"]}/lib/shdotenv/shdotenv" "${shdotenv_arguments[@]}")"
  output="$(echo "$output" | sed '2i // Do not edit this file since it is generated. Run "project run update_php_env" to update it.')"
  echo "$output"
}

_project_get_tags() {
  local project_name="$1"
  local -n result=$2
  local tags
  tags="$(_project_get_env_value "$project_name" "PROJECT_TAGS")"
  IFS=',' read -r -a result <<< "$tags"
}

_project_get_logs_dir() {
  local project_name="$1"
  local default=".project/logs"

  if [ "$project_name" == "$PROJECT_NAME" ]; then
    if [ -n "$PROJECT_LOGS_DIR" ]; then
      echo "$PROJECT_LOGS_DIR"
    else
      echo "$default"
    fi
  else
    # Retrieve the value from the project's env file.
    _project_get_env_value "$project_name" PROJECT_LOGS_DIR "" "$default"
  fi
}