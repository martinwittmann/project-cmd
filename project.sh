#!/bin/bash

declare -A PROJECT_PROJECTS

_project_cmd() {
  SETUP_ERROR=""
  # The path of project.sh.
  local __PROJECT_SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}" | xargs dirname)

  # Include setup functions.
  . "$__PROJECT_SCRIPT_PATH/_functions.sh"

  local project_name=""
  local project_path=""
  local project_tag=""
  PROJECT_TAG=""
  local command=""


  # Parse options

  # We need to reset OPTIND which should get written by getopts, but after
  # using the -t option once it keeps having an incorrect value.
  OPTIND=1
  while getopts ":p:t:" opt; do
    case $opt in
      p)
        project_name="$OPTARG"
        ;;

      t)
        project_tag="$OPTARG"
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

  if [ $# -ge 1 ]; then
    command="$1"
    shift
  fi

  . "$__PROJECT_SCRIPT_PATH/_setup.sh"

  # This sets up project-cmd, but not a project.
  _project_setup "$project_name" "$project_tag"

  if [ -n "$PROJECT_PATH" ]; then
    project_name="$PROJECT_NAME"
    project_path="$PROJECT_PATH"
  fi

  if [ -n "$SETUP_ERROR" ]; then
    project_show_error "Project-cmd setup error."
    return 1
  fi

  local not_found_message="No project found in current dir or any parent dirs."

  case $command in

      add)
        project_add_project "$@"
        ;;

      build_global_docker_images)
        project_build_global_docker_images "$@"
        ;;

      cd)
        project_name="$1"
        if [ -z $project_name ]; then
          project_show_error "Missing argument [project_name]."
          return 1
        fi

        if ! project_path=$(_project_get_project_path_by_name "$project_name"); then
          project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
          return 1
        fi
        project_show_message "You're now in project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\"."
        cd "$project_path"
        ;;

      compare_with_project)
        if ! project_path=$(_project_get_project_path); then
          return 1
        fi

        if ! project_name=$(_project_get_project_name "$project_path"); then
          return 1
        fi

        _project_setup_project "$project_name"
        local global_scripts="$__PROJECT_SCRIPT_PATH/_global-scripts.sh"
        source $global_scripts
        project_run_global_script compare_with_project "$1" "$2"
        ;;

      create)
        project_create_from_template "$@"
        ;;

      end)
        project_run_global_script "end"
        ;;

      get_env_value)
        local variable_name="$1"
        local project_name="${2:-${PROJECT_NAME}}"
        _project_get_env_value "$project_name" "$variable_name"
        ;;


      list)
        echo "The following projects were found:"
        for project_path in "${!PROJECT_PROJECTS[@]}"; do
          local scripts_path
          scripts_path=$(_project_get_scripts_path "$project_path")
          local project_name="${PROJECT_PROJECTS[$project_path]}"
          _project_get_project_status "$project_name" "$project_path" "short"
        done
        ;;

      ps)
        docker ps -a
        ;;

      remove)
        local project_name="$1"
        if [ -z "$project_name" ]; then
          project_show_error "You need to provide a project name."
          return 1
        fi

        local project_path
        if ! project_path=$(_project_get_project_path_by_name "$project_name"); then
          return 1
        fi

        project_name=$(_project_get_project_name "$project_path" "0")
        if [ -z "$project_name" ]; then
          project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
          return 1
        fi

        sudo unlink "/etc/project-cmd/projects.d/$project_name"
        ;;

      restart)
        _project_setup_project "$project_name"
        _project_run_script "$project_name" "$project_path" "restart" "$@"
        ;;

      run)
        if ! project_path=$(_project_get_project_path); then
          return 1
        fi

        if ! project_name=$(_project_get_project_name "$project_path"); then
          return 1
        fi

        local script_name="$1"
        shift
        _project_setup_project "$project_name"
        _project_run_script "$project_name" "$project_path" "$script_name" "$@"
        ;;

      start)
        if ! project_path=$(_project_get_project_path); then
          return 1
        fi

        if ! project_name=$(_project_get_project_name "$project_path"); then
          return 1
        fi

        _project_setup_project "$project_name"
        _project_run_script "$project_name" "$project_path" "start" "$@"
        if [ -n "$PROJECT_DOMAIN" ]; then
          _project_print_url "http://$PROJECT_DOMAIN"
        fi
        ;;

      stop)
        if ! project_path=$(_project_get_project_path); then
          project_show_error "$not_found_message"
          return 1
        fi

        if ! project_name=$(_project_get_project_name "$project_path"); then
          return 1
        fi

        _project_setup_project "$project_name"
        _project_run_script "$project_name" "$project_path" "stop" "$@"
        ;;

      "")
        _project_setup_project "$project_name"
        _project_run_script "$project_name" "$project_path" "status"
        ;;

      *)
        project_show_error "Unknown command \"$PROJECT_TEXT_YELLOW$command$PROJECT_TEXT_RESET\"."
        return 1
        ;;
  esac
}

_project_cmd "$@"
