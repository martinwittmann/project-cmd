#!/bin/bash

_project_populate_projects_array() {
  # Note that we can't use double quotes in the for loop as this breaks it for
  # some reason.
  for symlink in $PROJECT_PROJECTS_PATH/*; do
    if [ -L "$symlink" ]; then
      local project_path
      project_path=$(readlink -f "$symlink")
      if [ $? -ne 0 ]; then
        basename "$symlink"
        echo "Could not read $symlink"
        return 1
      fi
      PROJECT_PROJECTS["$project_path"]=$(basename "$symlink")
    fi
  done
}

_project_get_project_path_by_name() {
  project_name="$1"
  local item_name

  for item_path in "${!PROJECT_PROJECTS[@]}"; do
    local item_name="${PROJECT_PROJECTS[$item_path]}"
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

  if [[ -v PROJECT_PROJECTS["$current_path"] ]]; then
    echo $current_path
  elif [ "$current_path" == "/" ] && [ $show_errors -eq 1 ]; then
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

  if [[ -v PROJECT_PROJECTS["$project_path"] ]]; then
    echo "${PROJECT_PROJECTS["$project_path"]}"
  elif [ $show_errors -eq 1 ]; then
    project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
    return 1
  fi
}

# All messages are written to stderr to not pollute stdout.
project_show_error() {
  echo -e "$PROJECT_STATUS_ERROR $1" >&2
}

project_show_warning() {
  echo -e "$PROJECT_STATUS_WARNING $1" >&2
}

project_show_success() {
  echo -e "$PROJECT_STATUS_SUCCESS $1" >&2
}

project_show_message() {
  echo -e "$1" >&2
}

_project_get_scripts_path() {
  local project_path="$1"
  if [ -z "$project_path" ]; then
    project_path=$(_project_get_project_path)
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
  local project_path=$(_project_get_project_path_by_name "$project_name")
  local scripts_path=$(_project_get_scripts_path "$project_path")
  local script_filename="$scripts_path/$script_name.sh"

  if [ -f "$script_filename" ]; then
    . "$script_filename"
  fi

  if [ "$(type -t $function_name)" != "function" ]; then
    if [ $show_errors -eq 1 ]; then
      project_show_warning "The script \"${PROJECT_TEXT_YELLOW}${script_name}$PROJECT_TEXT_RESET\" does not exist in project ${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET."
    fi
    return 1
  fi
}

_project_run_script() {
  local project_name="$1"
  local project_path="$2"
  local script_name="$3"
  shift 3
  local script_filename=$(_project_get_script_path "$project_path" "$script_name")

  # We need to source the global scripts file to make sure these functions are
  # available for project script files.
  local global_scripts="$__PROJECT_SCRIPT_PATH/_global-scripts.sh"
  source $global_scripts

  if [ -f "$script_filename" ]; then
    # We need to source the script file to make all our variables and commands /
    # functions available to the script.

    if [ "$project_name" == "$PROJECT_NAME" ]; then
      source "$script_filename"
    else
      echo $(_project_setup_project "$project_name" && source "$script_filename")
    fi
  else
    project_show_error "$script_filename The script \"${PROJECT_TEXT_YELLOW}${script_name}$PROJECT_TEXT_RESET\" does not exist in project ${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET."
  fi
}

_project_get_project_names() {
  for item_path in "${!PROJECT_PROJECTS[@]}"; do
    echo "${PROJECT_PROJECTS[$item_path]}"
  done
}

_project_get_project_status() {
  local project_name="$1"
  local project_path="$2"
  local name_padding=$((10 - ${#project_name}))
  local script_filename=$(_project_get_script_path "$project_path" "status")
  local project_status

  if [ -f "$script_filename" ]; then
    project_status=$(_project_run_script "$project_name" "$project_path" "status" "short")
  else
    project_status="${PROJECT_TEXT_GRAY}unknown$PROJECT_TEXT_RESET"
  fi

  name_padding=$(printf "%${name_padding}s")
  local path_padding=$((60 - ${#project_path}))
  path_padding=$(printf "%${path_padding}s")

  echo -e " ${PROJECT_TEXT_YELLOW}${project_name}${name_padding}$PROJECT_TEXT_RESET $project_path${path_padding}$project_status"
}

project_get_docker_compose_path() {
  local project_name="${1:-${PROJECT_NAME}}"
  echo $(_project_setup_project "$project_name" && echo "$PROJECT_PATH/docker-compose.${PROJECT_ENV}.yml")
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
  local project_name="${1:-${PROJECT_NAME}}"

  # Output format can be "services" or "summary"
  local output_format="${2:-summary}"
  local compose_file=$(project_get_docker_compose_path)
  local status=$(docker compose -f "$compose_file" ps --format '{{.Name}} {{.Status}}')

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
    local container_name=$(echo "$line" | awk '{print $1}')
    local container_status=$(echo "$line" | tr '[:upper:]' '[:lower:]' | awk '{print $2}')


    if [ "$container_status" == "up" ]; then
      if [ "$project_status" == "down" ]; then
        project_status="partial"
      fi
    else
      all_services_up=false
    fi

    if [[ "$output_format" == "services" ]]; then
      local spaces=$((10 - ${#container_name}))
      spaces=$(printf "%${spaces}s")
      echo -n " $container_name:$spaces"
      _project_status_output $container_status
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
    echo -e "${PROJECT_TEXT_GREEN}${status}$PROJECT_TEXT_RESET"
  elif [ "$status" == "partial" ]; then
    echo -e "${PROJECT_TEXT_GREEN}${status}$PROJECT_TEXT_RESET"
  else
    echo -e "${PROJECT_TEXT_RED}${status}$PROJECT_TEXT_RESET"
  fi
}

_project_print_url() {
  local url="$1"
  echo -en "\nProject ${PROJECT_TEXT_YELLOW}$PROJECT_NAME${PROJECT_TEXT_RESET} available at: "
  echo -e "${PROJECT_TEXT_CYAN}\e]8;;$url\a$url\e]8;;\a${PROJECT_TEXT_RESET}"
  echo ""
}

_project_assert_project_exists() {
  local project_name="$1"
  local project_path="$2"
  if [ -z $project_path ]; then
    project_path=$(_project_get_project_path_by_name "$project_name")

    if [ $? -ne 0 ]; then
      return 1
    fi
  fi

  if [ -z $project_name ] || [ -z $project_path ] || [ ! -d $project_path ]; then
    project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
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

project_build_global_docker_images() {
  local dirnames="$1"
  if [ -z "$dirnames" ]; then
    project_show_error "You need to specify directory names, separated by ';' for which docker images will be built."
    return 1
  fi
  local env="${2:-prod}"
  local basepath="${3:-${__PROJECT_SCRIPT_PATH}/docker/${dirname}}"

  if [ ! -d "$basepath" ]; then
    project_show_error "Directory \"${PROJECT_TEXT_YELLOW}${basepath}$PROJECT_TEXT_RESET\" not found."
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
  local env="${2:-prod}"
  local basepath="${3:-${__PROJECT_SCRIPT_PATH}/docker/${dirname}}"
  local fullpath="$basepath/$dirname"

  if [ ! -d "$basepath" ]; then
    project_show_error "Directory \"${PROJECT_TEXT_YELLOW}${basepath}$PROJECT_TEXT_RESET\" not found. Skipping."
    echo ""
    exit 1
  fi

  if [ ! -d "$fullpath" ]; then
    project_show_error "Directory \"${PROJECT_TEXT_YELLOW}${fullpath}$PROJECT_TEXT_RESET\" not found. Skipping."
    echo ""
    exit 1
  fi

  project_show_message "Building image schwerpunkt/$dirname:$env..."
  docker build --build-arg APP_ENV=$env -t schwerpunkt/$dirname:$env "$fullpath"
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

project_render_template() {
  local template_arg="$1"
  local template_file="$1"
  shift

  local template_argument_format="[project_name]:[path]/[to]/[template]"

  if [ -z "$template_file" ]; then
    project_show_error -e "$PROJECT_STATUS_ERROR You need to specify a template in the form \"${PROJECT_TEXT_YELLOW}${template_argument_format}${PROJECT_TEXT_RESET}\" as first argument."
    return 1;
  fi

  # Extract part before the first ':'.
  local other_project_name="${template_file%%:*}"

  # Remove the everything up until the first ':' from the original string.
  template_file="${template_file#*:}"

  if [ -z "$other_project_name" ] || [ -z "$template_file" ]; then
    project_show_error "Invalid template argument \"${PROJECT_TEXT_YELLOW}${template_arg}${PROJECT_TEXT_RESET}\".\nPlease use the format \"${PROJECT_TEXT_YELLOW}${template_argument_format}${PROJECT_TEXT_RESET}\" and make sure the project and the corresponding path ([project_name]/.project/templates/[template]/path) exists."
    return 1
  fi

  # Resolve the template file
  local other_project_path
  other_project_path=$(_project_get_project_path_by_name "$other_project_name")

  # Add the extension if it wasn't added already.
  if [[ "$template_file" != *".jinja" ]]; then
    template_file="${template_file}.jinja"
  fi
  local templates_path
  templates_path=$(realpath "$other_project_path/.project/templates")
  template_file="$templates_path/$template_file"

  if [ ! -f "$template_file" ]; then
    project_show_error "Cannot find template \"${PROJECT_TEXT_YELLOW}${template_file}${PROJECT_TEXT_RESET}\"."
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
      project_show_warning "Empty value for key \"${PROJECT_TEXT_YELLOW}${key}${PROJECT_TEXT_RESET}\"."
    fi
    jinja_arguments+=('-D')
    jinja_arguments+=("$key=$value")
    shift 2  # Shift to the next pair
  done

  printf -v jinja_arguments_string "%q " "${jinja_arguments[@]}"
  (
    cd "$templates_path" || return 1
    jinja2 --strict "$template_file" "${jinja_arguments[@]}"
  )
}