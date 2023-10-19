#!/bin/bash

_project_cmd() {

  # The path of project.sh.
  local __PROJECT_SCRIPT_PATH=`realpath "${BASH_SOURCE[0]}" | xargs dirname`

  PROJECT_NAME=""
  PROJECT_PATH=""

  # Include setup functions.
  source "$__PROJECT_SCRIPT_PATH/_functions.sh"

  local PROJECT_NAME=""
  local COMMAND="status"

  # Parse options
  while getopts ":p:" opt; do
    case $opt in
      p)
        PROJECT_NAME="$OPTARG"
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        return 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        return 1
        ;;
    esac
  done

  # Set up variables and helpers after parsing options to allow setting/overriding
  # the project with -p [project_name].

  # Shift the options out
  shift $((OPTIND - 1))



  if [ "$COMMAND" == "cd" ]; then
      # when using the cd command we expect the project's name as second
      # argument which would override the -p option.
      local project_name="$2"

      if [ -z $project_name ]; then
        project_show_error "Missing argument [project_name]."
        return 1
      fi
  fi

  if [ $# -ge 1 ]; then
    COMMAND="$1"
  fi

  source "$__PROJECT_SCRIPT_PATH/_setup.sh"
  _project_setup "$project_name"
  if [ "$SETUP_ERROR" -eq 1 ]; then
    return 1
  fi

  case $COMMAND in
      status)
        _project_assert_project_exists
        echo "Show project status."
        ;;

      cd)
        _project_assert_project_exists
        cd "$project_path"
        ;;

      run)
        _project_assert_project_exists
        _project_execute_script "$2"
        ;;

      list)
        echo "The following projects were found:"
        for project_path in `find "$PROJECT_PROJECTS_PATH" -type l`; do
          project_name=`basename "$project_path"`
          local project_path=`realpath $project_path`
          local spaces=$((10 - ${#project_name}))
          spaces=`printf "%${spaces}s"`
          echo -e " ${PROJECT_TEXT_YELLOW}${project_name}${spaces}$PROJECT_TEXT_RESET: $project_path"
        done
        ;;

      *)
        project_show_error "Unknown command \"$PROJECT_TEXT_YELLOW$COMMAND$PROJECT_TEXT_RESET\"."
        ;;
  esac
}

_project_cmd