#!/bin/bash

_project_setup() {
  # Add our own .env variables.
  source "${p["_script_path"]}/.env"
  source "${p["_script_path"]}/_functions.sh"

  # Variables for easy text formatting.
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

  # Set up path variables.
  p["projects_path"]="/etc/project-cmd/projects.d"

  p["project_name"]="$1"
  p["project_tag"]="$2"

  # We need to declare it as global.
  _project_populate_projects_array

  if [ -z "${p["project_name"]}" ]; then
    p["project_name"]="$(_project_get_project_name "" "0")"
    p["project_path"]="$(_project_get_project_path "" "0")"
  else
    p["project_path"]="$(realpath "${p["projects_path"]}/${p["project_name"]}")"
    if [ ! -d "${p["project_path"]}" ]; then
      project_show_error "Project not found: \"${p["_text_yellow"]}${p["project_path"]}${p["_text_reset"]}\"."
      return 1
    fi
  fi
}

_project_setup_project() {
  p["project_name"]="$1"
  p["project_path"]="$(_project_get_project_path_by_name "${p["project_name"]}")"

  if [ $? -ne 0 ]; then
    project_show_error "Project \"${p["_text_yellow"]}${p["project_name"]}${p["_text_reset"]}\" not found."
    return 1
  fi

  _project_assert_project_exists "${p["project_name"]}" "${p["project_path"]}"
  local scripts_path="$(_project_get_scripts_path "${p["project_path"]}")"

  if [ $? -ne 0 ]; then
    project_show_error "Project scripts directory \"$scripts_path\" not found."
    p["setup_error"]="1"
  fi

  # Set everything defined in .env as variables for this script.
  p["env_file"]="${p["project_path"]}/.env"

  if [ ! -f "${p["env_file"]}" ]; then
    project_show_error "Project env file \"${p["env_file"]}\" not found."
    p["setup_error"]="1"
  fi

  if [ -f "${p["env_file"]}" ]; then
    source "${p["env_file"]}"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing env file \"${p["env_file"]}\"."
    p["setup_error"]="1"
    return 1
  fi

  # Allow env files for tags to override variables.
  p["tag_env_file"]="${p["project_path"]}/.env.${p["project_tag"]}"

  if [ -n "${p["project_tag"]}" ] && [ -f "${p["tag_env_file"]}" ]; then
    source "${p["tag_env_file"]}"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing tag env file \"${p["tag_env_file"]}\"."
    p["setup_error"]="1"
    return 1
  fi

  # TODO Is there a better place to do this?
  local project_script_include="${p["project_path"]}/.project/scripts/_include.sh"
  if [ -f "$project_script_include" ]; then
    source "$project_script_include"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing project script include \"$project_script_include\"."
    p["setup_error"]="1"
    return 1
  fi
}
