#!/bin/bash

declare -A PROJECT_PROJECTS

_project_cmd() {
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
  _project_setup "" "$project_tag"
  
  if [ -n "$PROJECT_PATH" ]; then
    project_name="$PROJECT_NAME"
    project_path="$PROJECT_PATH"
  fi

  if [ "$SETUP_ERROR" -eq 1 ]; then
    return 1
  fi

  local not_found_message="No project found in current dir or any parent dirs."

  case $command in

      add)
        local project_name="$2"
        if [ -z "$project_name" ]; then
          project_show_error "You need to provide a project name."
          return 1
        fi

        local project_path="$3"
        if [ -z "$project_path" ]; then
          project_show_error "You need to provide a project path."
          return 1
        fi
        project_path=$(realpath "$project_path")

        if [ ! -d "$project_path" ]; then
          project_show_error "The project path \"$PROJECT_TEXT_YELLOW${project_path}$PROJECT_TEXT_RESET\" does not exist."
          return 1
        fi
        local symlink="$PROJECT_PROJECTS_PATH/$project_name"
        sudo ln -s "$project_path" "$symlink"
        ;;

      build_global_docker_images)
        shift
        project_build_global_docker_images "$@"
        ;;

      cd)
        project_name="$2"
        if ! project_path=$(_project_get_project_path_by_name "$project_name"); then
          project_show_error "Project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\" not found."
          return 1
        fi
        project_show_message "You're now in project \"${PROJECT_TEXT_YELLOW}${project_name}$PROJECT_TEXT_RESET\"."
        cd "$project_path"
        ;;

      compare_with_project)
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

        _project_setup_project "$project_name"
        local global_scripts="$__PROJECT_SCRIPT_PATH/_global-scripts.sh"
        source $global_scripts
        project_run_global_script compare_with_project "$2" "$3"
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

        _project_setup_project "$project_name"
        _project_run_script "$project_name" "end"
        ;;

      get_env_value)
        shift
        local variable_name="$1"
        _project_get_env_value "$PROJECT_NAME" "$variable_name"
        ;;


      list)
        echo "The following projects were found:"
        for project_path in "${!PROJECT_PROJECTS[@]}"; do
          local scripts_path=$(_project_get_scripts_path "$project_path")
          local project_name="${PROJECT_PROJECTS[$project_path]}"
          _project_get_project_status "$project_name" "$project_path" "short"
        done
        ;;

      ps)
        docker ps -a
        ;;

      remove)
        local project_name
        project_name="$2"
        if [ -z "$2" ]; then
          project_show_error "You need to provide a project name."
          return 1
        fi

        local project_path
        project_path=$(_project_get_project_path_by_name "$project_name")
        if [ $? -ne 0 ]; then
          project_show_error "$not_found_message"
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

        _project_setup_project "$project_name"
        _project_run_script "$project_name" "$project_path" "restart" "$@"
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

        _project_setup_project "$project_name"

        local script_name="$2"
        shift 2
        _project_run_script "$project_name" "$project_path" "$script_name" "$@"
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

        _project_setup_project "$project_name"
        _project_run_script "$project_name" "$project_path" "start" "$@"
        if [ -n "$PROJECT_DOMAIN" ]; then
          _project_print_url "http://$PROJECT_DOMAIN"
        fi
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
