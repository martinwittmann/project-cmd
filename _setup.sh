#!/bin/bash

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
PROJECT_PROJECTS_PATH=`realpath ~/.project2`

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
  PROJECT_PATH=`_project_get_project_path`
  PROJECT_NAME=`basename "$PROJECT_PATH"`
else
  PROJECT_PATH=`realpath "$PROJECT_PROJECTS_PATH/$PROJECT_NAME"`
  if [ ! -d "$PROJECT_PATH" ]; then
    project_show_error "Project not found: \"$PROJECT_TEXT_YELLOW$PROJECT_PATH$PROJECT_TEXT_RESET\"."
    exit 1
  fi
fi

if [ $? -ne 0 ]; then
  echo "No project found."
  exit 1
fi

SCRIPTS_PATH=`realpath "$PROJECT_PATH/scripts2"`

if [ $? -ne 0 ]; then
exit 1
fi

# Set everything defined in .env as variables for this script.
PROJECT_ENV_FILENAME="$PROJECT_PATH/.env"
#set -o allexport
source "$PROJECT_ENV_FILENAME"
#set +o allexport
