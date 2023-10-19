#!/bin/bash

_project_cmd() {
  # The path of project.sh.
  local __PROJECT_SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}" | xargs dirname)

  # Include setup functions.
  source "$__PROJECT_SCRIPT_PATH/_functions.sh"

  local project_name=""
  local project_path=""
  local command="status"

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

  source "$__PROJECT_SCRIPT_PATH/_setup.sh"
  _project_setup

  if [ "$SETUP_ERROR" -eq 1 ]; then
    return 1
  fi

  case $command in
      status)
        _project_setup_project "$project_name"
        echo "Show project status."
        ;;

      cd)
        project_name="$2"
        project_path=$(_project_get_project_path_by_name "$project_name")

        if [ $? -ne 0 ]; then
          return 1
        fi
        project_show_message "You're now in project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\"."
        cd "$project_path"
        ;;

      run)
        project_path=$(_project_get_project_path)
        project_name=$(_project_get_project_name "$project_path")
        _project_setup_project "$project_name" "$project_path"
        local script_name="$2"
        _project_execute_script "$project_name" "$script_name"
        ;;

      list)
        echo "The following projects were found:"
        for project_path in "${!PROJECT_PROJECTS[@]}"; do
          local scripts_path=$(_project_get_scripts_path "$project_path")
          source "$scripts_path/status.sh"
          local project_name="${PROJECT_PROJECTS[$project_path]}"
          local name_padding=$((10 - ${#project_name}))
          name_padding=$(printf "%${name_padding}s")
          local status=$(_project_execute_script "$project_name" "status" "summary")
          local path_padding=$((60 - ${#project_path}))
          path_padding=$(printf "%${path_padding}s")

          echo -e " ${PROJECT_TEXT_YELLOW}${project_name}${name_padding}$PROJECT_TEXT_RESET $project_path${path_padding}$status"
        done
        ;;

      *)
        project_show_error "Unknown command \"$PROJECT_TEXT_YELLOW$command$PROJECT_TEXT_RESET\"."
        ;;
  esac
}

_project_cmd "$@"
