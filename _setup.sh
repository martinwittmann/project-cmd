#!/bin/bash

_project_setup() {
  SETUP_ERROR=0

  # Set up variables for easy text formatting.
  PROJECT_TEXT_RESET="\e[0m"
  PROJECT_TEXT_RED="\e[31m"
  PROJECT_TEXT_GREEN="\e[32m"
  PROJECT_TEXT_YELLOW="\e[33m"
  PROJECT_TEXT_BOLD="\e[1m"
  PROJECT_STATUS_SUCCESS="$PROJECT_TEXT_GREEN$PROJECT_TEXT_BOLD[OK]$PROJECT_TEXT_RESET"
  PROJECT_STATUS_ERROR="$PROJECT_TEXT_RED$PROJECT_TEXT_BOLD[ERROR]$PROJECT_TEXT_RESET"
  PROJECT_STATUS_WARNING="$PROJECT_TEXT_YELLOW$PROJECT_TEXT_BOLD[WARNING]$PROJECT_TEXT_RESET"

  # Set up path variables.
  PROJECT_PROJECTS_PATH=$(realpath ~/.projects)

  PROJECT_NAME="$1"

  # We need to declare it as global.
  declare -Ag PROJECT_PROJECTS
  _project_populate_projects_array

  if [ -z "$PROJECT_NAME" ]; then
    PROJECT_PATH=$(_project_get_project_path)
    PROJECT_NAME=$(basename "$PROJECT_PATH")
  else
    PROJECT_PATH=$(realpath "$PROJECT_PROJECTS_PATH/$PROJECT_NAME")
    if [ ! -d "$PROJECT_PATH" ]; then
      project_show_error "Project not found: \"$PROJECT_TEXT_YELLOW$PROJECT_PATH$PROJECT_TEXT_RESET\"."
      return 1
    fi
  fi

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

_project_setup_project() {
  PROJECT_NAME="$1"
  if [ -z $project_path ]; then
    PROJECT_PATH=$(_project_get_project_path_by_name "$PROJECT_NAME")
  fi

  _project_assert_project_exists "$PROJECT_NAME" "$PROJECT_PATH"
  SCRIPTS_PATH=$(_project_get_scripts_path "$PROJECT_PATH")

  if [ $? -ne 0 ]; then
    project_show_error "Project scripts directory \"$SCRIPTS_PATH\" not found."
    SETUP_ERROR=1
  fi

  # Set everything defined in .env as variables for this script.
  PROJECT_ENV_FILENAME="$PROJECT_PATH/.env"

  if [ ! -f "$PROJECT_ENV_FILENAME" ]; then
    project_show_error "Project env file \"$PROJECT_ENV_FILENAME\" not found."
    SETUP_ERROR=1
  fi

  #set -o allexport
  if [ -f "$PROJECT_ENV_FILENAME" ]; then
    source "$PROJECT_ENV_FILENAME"
  fi
  #set +o allexport


  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing env file \"$PROJECT_ENV_FILENAME\"."
    SETUP_ERROR=1
    return 1
  fi
}
