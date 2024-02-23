#!/bin/bash

_project_cmd() {
  # The path of project.sh.
  local __PROJECT_SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}" | xargs dirname)

  # Include setup functions.
  . "$__PROJECT_SCRIPT_PATH/_functions.sh"

  local project_name=""
  local project_path=""
  local command=""

  # Parse options
  while getopts ":p:" opt; do
    case $opt in
      p)
        project_name="$OPTARG"
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

  # Shift the options out
  shift $((OPTIND - 1))



  if [ "$command" == "cd" ]; then
      # when using the cd command we expect the project's name as second
      # argument which would override the -p option.
      local project_name="$2"

      if [ -z $project_name ]; then
        project_show_error "Missing argument [project_name]."
        return 1
      fi
  fi

  if [ $# -ge 1 ]; then
    command="$1"
  fi

  . "$__PROJECT_SCRIPT_PATH/_setup.sh"
  _project_setup
  
  if [ ! -z "$PROJECT_PATH" ]; then
    project_name="$PROJECT_NAME"
    project_path="$PROJECT_PATH"
  fi

  if [ "$SETUP_ERROR" -eq 1 ]; then
    return 1
  fi

  local not_found_message="No project found in current dir or any parent dirs."

  case $command in

      cd)
        project_name="$2"
        project_path=$(_project_get_project_path_by_name "$project_name")

        if [ $? -ne 0 ]; then
          project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
          return 1
        fi
        project_show_message "You're now in project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\"."
        cd "$project_path"
        ;;

      run)
        project_path=$(_project_get_project_path)
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        project_name=$(_project_get_project_name "$project_path")
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        _project_setup_project "$project_name" "$project_path"

        local script_name="$2"
        shift
        shift
        _project_execute_script "$project_name" "$script_name" "$@"
        ;;

      list)
        echo "The following projects were found:"
        for project_path in "${!PROJECT_PROJECTS[@]}"; do
          local scripts_path=$(_project_get_scripts_path "$project_path")
          local project_name="${PROJECT_PROJECTS[$project_path]}"
          _project_get_project_status "$project_name" "summary"
        done
        ;;

      start)
        project_path=$(_project_get_project_path)
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        project_name=$(_project_get_project_name "$project_path")
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        _project_setup_project "$project_name" "$project_path"
        _project_execute_script "$project_name" "start"
        _project_print_url "http://$PROJECT_DOMAIN"
        ;;

      stop)
        project_path=$(_project_get_project_path)
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        project_name=$(_project_get_project_name "$project_path")
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        _project_setup_project "$project_name" "$project_path"
        _project_execute_script "$project_name" "stop"
        ;;

      end)
        project_path=$(_project_get_project_path)
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        project_name=$(_project_get_project_name "$project_path")
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
          return 1
        fi

        _project_setup_project "$project_name" "$project_path"
        _project_execute_script "$project_name" "end"
        ;;

      "")
        _project_setup_project "$project_name"
        _project_execute_script "$project_name" "status" "$@"
        ;;

      *)
        project_show_error "Unknown command \"$PROJECT_TEXT_YELLOW$command$PROJECT_TEXT_RESET\"."
        ;;
  esac
}

_project_cmd "$@"
