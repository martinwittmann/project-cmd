#!/bin/bash

_project_populate_projects_array() {
  # Note that we can't use double quotes in the for loop as this breaks it for
  # some reason.
  for symlink in $PROJECT_PROJECTS_PATH/*; do
    if [ -L "$symlink" ]; then
      local project_path=`readlink -f "$symlink"`
      PROJECT_PROJECTS["$project_path"]=`basename "$symlink"`
    fi
  done
}

_project_get_name_by_path() {
  local target_dir=`realpath "$1"`
  # Note that we can't use double quotes in the for loop as this breaks it for
  # some reason.
  for symlink in $PROJECT_PROJECTS_PATH/*; do
    link_target=`readlink -f $symlink`
    if [ -L "$symlink" ] && [ "$link_target" == "$target_dir" ]; then
      echo `basename $symlink`
      return 0
    fi
  done

  return 1
}

_project_get_project_path() {
  local current_path="$1"

  if [ -z "$current_path" ]; then
    current_path=`pwd`
  fi

  if [[ -v PROJECT_PROJECTS["$current_path"] ]]; then
    echo $current_path
  elif [ "$current_path" == "/" ]; then
    return 1
  else
    current_path=`realpath "$current_path/.."`
    _project_get_project_path "$current_path"
  fi
}

project_show_error() {
  echo -e "$PROJECT_STATUS_ERROR $1"
}

project_show_warning() {
  echo -e "$PROJECT_STATUS_WARNING $1"
}

project_show_success() {
  echo -e "$PROJECT_STATUS_SUCCESS $1"
}

_project_execute_script() {
  SCRIPT_NAME="${1:-status}"
  FUNCTION_NAME="_project_run_$SCRIPT_NAME"
  SCRIPT_FILENAME=`realpath "$SCRIPTS_PATH/$SCRIPT_NAME.sh"`
  if [ ! -f "$SCRIPT_FILENAME" ]; then
    project_show_error "Script function $PROJECT_TEXT_YELLOW$FUNCTION_NAME$PROJECT_TEXT_RESET not found."
  fi

  source "$SCRIPT_FILENAME"


  if [ "$(type -t $FUNCTION_NAME)" != "function" ] && [ -f "$SCRIPT_FILENAME" ]; then
    source "$SCRIPT_FILENAME"
  fi

  eval "$FUNCTION_NAME"
}

_project_assert_project_exists() {
  if [ -z $PROJECT_NAME ] || [ -z $PROJECT_PATH ] || [ ! -d $PROJECT_PATH ]; then
    project_show_error "Project \"${PROJECT_TEXT_YELLOW}${PROJECT_NAME}$PROJECT_TEXT_RESET\" not found."
  fi
}
