#!/bin/bash

# The list of projects. Each key is the path, each value is the project's name.
declare -A PROJECTS

  # Static variables for easy text formatting.
  TEXT_RESET="\e[0m"
  TEXT_RED="\e[31m"
  TEXT_GREEN="\e[32m"
  TEXT_GRAY="\e[2;37m"
  TEXT_YELLOW="\e[33m"
  TEXT_CYAN="\e[36m"
  TEXT_BOLD="\e[1m"

_project_setup() {
  p["_status_success"]="${TEXT_GREEN}${TEXT_BOLD}[OK]${TEXT_RESET}"
  p["_status_warning"]="${TEXT_YELLOW}${TEXT_BOLD}[WARNING]${TEXT_RESET}"
  p["_status_error"]="${TEXT_RED}${TEXT_BOLD}[ERROR]${TEXT_RESET}"


  p["project_name"]="$1"
  p["project_tag"]="$2"

  # Set up path variables.
  p["projects_path"]="/etc/project-cmd/projects.d"

  # Add our own .env variables.
  source "${p["_script_path"]}/.env"
  source "${p["_script_path"]}/_functions.sh"

  # We need to declare it as global.
  _project_populate_projects_array

  if [ -z "$PROJECT_NAME" ]; then
    p["project_name"]="$(_project_get_project_name "" "0")"
    p["project_path"]="$(_project_get_project_path "" "0")"
  else
    p["project_path"]="$(realpath "${p["projects_path"]}/$PROJECT_NAME")"
    if [ ! -d "$PROJECT_PATH" ]; then
      project_show_error "Project not found: \"${TEXT_YELLOW}$PROJECT_PATH${TEXT_RESET}\"."
      return 1
    fi
  fi
}

_project_setup_project() {
  PROJECT_NAME="$1"
  PROJECT_PATH="$(_project_get_project_path_by_name "$PROJECT_NAME")"

  if [ $? -ne 0 ]; then
    project_show_error "Project \"${TEXT_YELLOW}$PROJECT_NAME${TEXT_RESET}\" not found."
    return 1
  fi

  _project_assert_project_exists "$PROJECT_NAME" "$PROJECT_PATH"
  local scripts_path
  scripts_path="$(_project_get_scripts_path "$PROJECT_PATH")"

  if [ $? -ne 0 ]; then
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
  p["tag_env_file"]="$PROJECT_PATH/.env.${p["project_tag"]}"

  if [ -n "${p["project_tag"]}" ] && [ -f "${p["tag_env_file"]}" ]; then
    source "${p["tag_env_file"]}"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing tag env file \"${p["tag_env_file"]}\"."
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
