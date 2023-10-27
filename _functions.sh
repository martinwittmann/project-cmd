#!/bin/bash

_project_populate_projects_array() {
  # Note that we can't use double quotes in the for loop as this breaks it for
  # some reason.
  for symlink in $PROJECT_PROJECTS_PATH/*; do
    if [ -L "$symlink" ]; then
      local project_path=$(readlink -f "$symlink")
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

  project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
  return 1
}

_project_get_project_path() {
  local current_path="$1"

  if [ -z "$current_path" ]; then
    current_path=$(pwd)
  fi

  if [[ -v PROJECT_PROJECTS["$current_path"] ]]; then
    echo $current_path
  elif [ "$current_path" == "/" ]; then
    return 1
  else
    current_path=$(realpath "$current_path/..")
    _project_get_project_path "$current_path"
  fi
}

_project_get_project_name() {
  local project_path="$1"

  if [ -z "$project_path" ]; then
    project_path=$(_project_get_project_path)
  fi

  if [[ -v PROJECT_PROJECTS["$project_path"] ]]; then
    echo "${PROJECT_PROJECTS["$project_path"]}"
  else
    project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
    return 1
  fi
}

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

_project_load_script() {
  local project_name="$1"
  local script_name="$2"
  local function_name="_project_${project_name}_run_$script_name"
  local project_path=$(_project_get_project_path_by_name "$project_name")
  local scripts_path=$(_project_get_scripts_path "$project_path")
  local script_filename="$scripts_path/$script_name.sh"

  if [ -f "$script_filename" ]; then
    source "$script_filename"
  fi

  if [ "$(type -t $function_name)" != "function" ]; then
    project_show_warning "The script \"${PROJECT_TEXT_YELLOW}${script_name}$PROJECT_TEXT_RESET\" does not exist in project ${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET."
    return 1
  fi
}

_project_execute_script() {
  local project_name="$1"
  local script_name="${2:-status}"
  local function_name="_project_${project_name}_run_$script_name"

  # Remove the first 2 arguments so we can pass the rest to the function call later.
  shift
  shift

  _project_load_script "$project_name" "$script_name"

  if [ $? -eq 0 ]; then
    eval "$function_name $@"
  else
    project_show_error "Error loading script $script_name."
  fi
}

_project_get_project_names() {
  for item_path in "${!PROJECT_PROJECTS[@]}"; do
    echo "${PROJECT_PROJECTS[$item_path]}"
  done
}

_project_get_project_status() {
  local project_name="$1"
  local name_padding=$((10 - ${#project_name}))
  local script_filename="$scripts_path/status.sh"
  local project_status
  _project_load_script "$project_name" "status"

  if [ $? -eq 0 ]; then
    project_status=$(_project_execute_script "$project_name" "status" "summary")
  else
    project_status="${PROJECT_TEXT_GRAY}unknown$PROJECT_TEXT_RESET"
  fi

  name_padding=$(printf "%${name_padding}s")
  local path_padding=$((60 - ${#project_path}))
  path_padding=$(printf "%${path_padding}s")

  echo -e " ${PROJECT_TEXT_YELLOW}${project_name}${name_padding}$PROJECT_TEXT_RESET $project_path${path_padding}$project_status"
}

_project_get_project_status_via_docker_compose() {
  local project_name="$1"
  local project_path=$(_project_get_project_path_by_name "$project_name")

  # Output format can be "services" or "summary"
  local output_format="${2:-services}"

  local compose_filename="$project_path/docker-compose.yml"
  local status=$(docker compose -f "$compose_filename" ps --format '{{.Name}} {{.Status}}')

  local project_status="down"
  local all_services_up=true

  if [[ "$output_format" == "services" ]]; then
    echo -e "Containers for project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\":"
  fi

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
