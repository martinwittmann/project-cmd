#!/bin/bash

declare -A PROJECTS

_project_setup() {
  # The list of projects. Each key is the path, each value is the project's name.

  # Static variables for easy text formatting.
  TEXT_RESET="\e[0m"
  TEXT_RED="\e[31m"
  TEXT_GREEN="\e[32m"
  TEXT_GRAY="\e[2;37m"
  TEXT_YELLOW="\e[33m"
  TEXT_CYAN="\e[36m"
  TEXT_BOLD="\e[1m"

  p["_status_success"]="${TEXT_GREEN}${TEXT_BOLD}[OK]${TEXT_RESET}"
  p["_status_warning"]="${TEXT_YELLOW}${TEXT_BOLD}[WARNING]${TEXT_RESET}"
  p["_status_error"]="${TEXT_RED}${TEXT_BOLD}[ERROR]${TEXT_RESET}"
  p["_status_danger"]="${TEXT_RED}${TEXT_BOLD}[DANGER]${TEXT_RESET}"

  # Set up path variables.
  p["projects_path"]="/etc/project-cmd/projects.d"

  # Add our own .env variables.
  source "${p["_script_path"]}/.env"
  source "${p["_script_path"]}/_functions.sh"

  # We need to declare it as global.
  _project_populate_projects_array
}

_project_setup_project() {
  PROJECT_NAME="$1"
  PROJECT_TAG="$2"

  if [ -z "$PROJECT_NAME" ]; then
    # Set project name and path based on the current work dir, since none was set via the option -p.
    if ! PROJECT_PATH=$(_project_get_project_path); then
      project_show_error "Project \"${TEXT_YELLOW}${PROJECT_NAME}${TEXT_RESET}\" not found."
      return 1
    fi

    if ! PROJECT_NAME=$(_project_get_project_name "$PROJECT_PATH"); then
      project_show_error "No project found for path \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\"."
      return 1
    fi
  elif ! PROJECT_PATH="$(_project_get_project_path_by_name "$PROJECT_NAME")"; then
    project_show_error "Project \"${TEXT_YELLOW}${PROJECT_PATH}${TEXT_RESET}\" not found."
    return 1
  fi

  _project_assert_project_exists "$PROJECT_NAME" "$PROJECT_PATH"

  local scripts_path
  if ! scripts_path="$(_project_get_scripts_path "$PROJECT_PATH")"; then
    project_show_error "Project scripts directory \"$scripts_path\" not found."
    p["setup_error"]="1"
  fi

  # Set everything defined in .env as variables for this script.
  p["env_file"]="$PROJECT_PATH/.env"

  if [ ! -f "${p["env_file"]}" ]; then
    project_show_error "Project env file \"${p["env_file"]}\" not found."
    p["setup_error"]="1"
  fi

  if [ -f "${p["env_file"]}" ]; then
    source "${p["env_file"]}"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing project env file \"${p["env_file"]}\"."
    p["setup_error"]="1"
    return 1
  fi

  # Allow env files for tags to override variables.
  local tag_env_file="$PROJECT_PATH/.env.${PROJECT_TAG}"

  if [ -n "${PROJECT_TAG}" ] && [ -f "$tag_env_file" ]; then
    source "$tag_env_file"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing tag env file \"$tag_env_file\"."
    p["setup_error"]="1"
    return 1
  fi

  # TODO Is there a better place to do this?
  local project_script_include="$PROJECT_PATH/.project/scripts/_include.sh"
  if [ -f "$project_script_include" ]; then
    source "$project_script_include"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing project script include \"$project_script_include\"."
    p["setup_error"]="1"
    return 1
  fi
}
