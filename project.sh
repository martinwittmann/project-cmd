#!/bin/bash

# The path of project.sh.
__PROJECT_SCRIPT_PATH=`realpath "${BASH_SOURCE[0]}" | xargs dirname`

# Include setup functions.
source "$__PROJECT_SCRIPT_PATH/_functions.sh"

PROJECT_NAME=""
COMMAND="status"

# Parse options
while getopts ":p:" opt; do
  case $opt in
    p)
      PROJECT_NAME="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Set up variables and helpers after parsing options to allow setting/overriding
# the project with -p [project_name].

# Shift the options out
shift $((OPTIND - 1))

# Check if the command argument is provided
if [ $# -ge 1 ]; then
    COMMAND=$1

    if [ "$COMMAND" == "cd" ]; then
        # When using the cd command we expect the project's name as second
        # argument which would override the -p option.
        PROJECT_NAME="$2"
    fi

    source "$__PROJECT_SCRIPT_PATH/_setup.sh" "$PROJECT_NAME"

    case $COMMAND in
        cd)
            cd "$PROJECT_PATH"
            ;;

        run)
            _project_execute_script "$2"
            ;;
    esac
else
  echo "Usage: $0 -p [name] <command>"
  exit 1
fi