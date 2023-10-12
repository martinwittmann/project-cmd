#!/bin/bash

_project_get_project_path() {
    CURRENT_PATH="$1"

    if [ -z "$CURRENT_PATH" ]; then
        CURRENT_PATH=`pwd`
    fi

    ENV_FILE=`realpath "$CURRENT_PATH/.env"`

    if [ -f "$ENV_FILE" ]; then
        echo $CURRENT_PATH
    elif [ "$CURRENT_PATH" == "/" ]; then
        exit 1
    else
        CURRENT_PATH=`realpath "$CURRENT_PATH/.."`
        _project_get_project_path "$CURRENT_PATH"
    fi
    exit 0
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