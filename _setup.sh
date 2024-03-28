#!/bin/bash

# The list of projects. Each key is the path, each value is the project's name.
declare -A p_projects
# The current project's environment variables / values.
declare -A p_env

_project_setup() {
  # Static variables for easy text formatting.
  p["_text_reset"]="\e[0m"
  p["_text_red"]="\e[31m"
  p["_text_green"]="\e[32m"
  p["_text_gray"]="\e[2;37m"
  p["_text_yellow"]="\e[33m"
  p["_text_cyan"]="\e[36m"
  p["_text_bold"]="\e[1m"

  p["_status_success"]="${p["_text_green"]}${p["_text_bold"]}[OK]${p["_text_reset"]}"
  p["_status_warning"]="${p["_text_yellow"]}${p["_text_bold"]}[WARNING]${p["_text_reset"]}"
  p["_status_error"]="${p["_text_red"]}${p["_text_bold"]}[ERROR]${p["_text_reset"]}"


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
      project_show_error "Project not found: \"${p["_text_yellow"]}$PROJECT_PATH${p["_text_reset"]}\"."
      return 1
    fi
  fi
}

_project_setup_project() {
  PROJECT_NAME="$1"
  PROJECT_PATH="$(_project_get_project_path_by_name "$PROJECT_NAME")"

  if [ $? -ne 0 ]; then
    project_show_error "Project \"${p["_text_yellow"]}$PROJECT_NAME${p["_text_reset"]}\" not found."
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
