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
  PROJECT_PROJECTS_PATH=`realpath ~/.projects`

  PROJECT_NAME="$1"

  declare -A PROJECT_PROJECTS

  _project_populate_projects_array
  if [ -z "$PROJECT_NAME" ]; then
    PROJECT_PATH=`_project_get_project_path`
    PROJECT_NAME=`basename "$PROJECT_PATH"`
  else
    PROJECT_PATH=`realpath "$PROJECT_PROJECTS_PATH/$PROJECT_NAME"`
    if [ ! -d "$PROJECT_PATH" ]; then
      project_show_error "Project not found: \"$PROJECT_TEXT_YELLOW$PROJECT_PATH$PROJECT_TEXT_RESET\"."
      return 1
    fi
  fi

  echo $PROJECT_NAME
  echo $PROJECT_PATH

  if [ ! -z $PROJECT_NAME ] && [ ! -z $PROJECT_PATH ]; then
    SCRIPTS_PATH=`realpath "$PROJECT_PATH/scripts"`

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
    source "$PROJECT_ENV_FILENAME"
    #set +o allexport


    if [ $? -ne 0 ]; then
      project_show_error "Error sourcing env file \"$PROJECT_ENV_FILENAME\"."
      SETUP_ERROR=1
    fi
  fi
}