#!/bin/bash


_project_setup() {
  SETUP_ERROR=0

  # Set up variables for easy text formatting.
  PROJECT_TEXT_RESET="\e[0m"
  PROJECT_TEXT_RED="\e[31m"
  PROJECT_TEXT_GREEN="\e[32m"
  PROJECT_TEXT_GRAY="\e[2;37m"
  PROJECT_TEXT_YELLOW="\e[33m"
  PROJECT_TEXT_CYAN="\e[36m"
  PROJECT_TEXT_BOLD="\e[1m"
  PROJECT_STATUS_SUCCESS="$PROJECT_TEXT_GREEN$PROJECT_TEXT_BOLD[OK]$PROJECT_TEXT_RESET"
  PROJECT_STATUS_ERROR="$PROJECT_TEXT_RED$PROJECT_TEXT_BOLD[ERROR]$PROJECT_TEXT_RESET"
  PROJECT_STATUS_WARNING="$PROJECT_TEXT_YELLOW$PROJECT_TEXT_BOLD[WARNING]$PROJECT_TEXT_RESET"

  # Set up path variables.
  PROJECT_PROJECTS_PATH="/etc/project-cmd/projects.d"
  PROJECT_PROJECTS=()

  PROJECT_NAME="$1"
  PROJECT_TAG="$2"

  # We need to declare it as global.
  _project_populate_projects_array

  if [ -z "$PROJECT_NAME" ]; then
    PROJECT_PATH=$(_project_get_project_path "" "0")
    PROJECT_NAME=$(_project_get_project_name "" "0")
  else
    PROJECT_PATH=$(realpath "$PROJECT_PROJECTS_PATH/$PROJECT_NAME")
    if [ ! -d "$PROJECT_PATH" ]; then
      project_show_error "Project not found: \"$PROJECT_TEXT_YELLOW$PROJECT_PATH$PROJECT_TEXT_RESET\"."
      return 1
    fi
  fi
}

_project_setup_project() {
  PROJECT_NAME="$1"
  PROJECT_PATH=$(_project_get_project_path_by_name "$PROJECT_NAME")

  if [ $? -ne 0 ]; then
    project_show_error "Project \"${PROJECT_TEXT_YELLOW}${PROJECT_NAME}${PROJECT_TEXT_RESET}\" not found."
    return 1
  fi

  _project_assert_project_exists "$PROJECT_NAME" "$PROJECT_PATH"
  local scripts_path=$(_project_get_scripts_path "$PROJECT_PATH")

  if [ $? -ne 0 ]; then
    project_show_error "Project scripts directory \"$scripts_path\" not found."
    SETUP_ERROR=1
  fi

  # Set everything defined in .env as variables for this script.
  PROJECT_ENV_FILENAME="$PROJECT_PATH/.env"

  if [ ! -f "$PROJECT_ENV_FILENAME" ]; then
    project_show_error "Project env file \"$PROJECT_ENV_FILENAME\" not found."
    SETUP_ERROR=1
  fi

  if [ -f "$PROJECT_ENV_FILENAME" ]; then
    . "$PROJECT_ENV_FILENAME"
  fi

  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing env file \"$PROJECT_ENV_FILENAME\"."
    SETUP_ERROR=1
    return 1
  fi

  # Allow env files for tags to override variables.
  local tag_env_file="$PROJECT_PATH/.env.$PROJECT_TAG"

  if [ -f "$tag_env_file" ]; then
    . "$tag_env_file"
  fi


  if [ $? -ne 0 ]; then
    project_show_error "Error sourcing tag env file \"$tag_env_file\"."
    SETUP_ERROR=1
    return 1
  fi
}
