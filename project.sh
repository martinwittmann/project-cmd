#!/bin/bash

# Bootstrapping.
declare -A p
p["_script_path"]="$(realpath "${BASH_SOURCE[0]}" | xargs dirname)"
source "${p["_script_path"]}/_setup.sh"

_project_cmd() {
  # The path of project.sh.

  local project_name=""
  local project_path=""
  local project_tag=""
  local command=""

  # Parse options

  # We need to reset OPTIND which should get written by getopts, but after
  # using the -t option once it keeps having an incorrect value.
  OPTIND=1
  while getopts "vp:t:" opt; do
    case $opt in
      v)
        echo "Project-cmd version 0.3"
        return 0
        ;;

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

        if [ "$OPTARG" != "v" ]; then
          echo "Option -$OPTARG requires an argument." >&2
          return 1
        fi
        ;;
    esac
  done

  # Shift the options out
  shift $((OPTIND - 1))

  if [ $# -ge 1 ]; then
    command="$1"
    shift
  fi

  # This sets up project-cmd, but not a project. Each command script needs to call
  # _project_setup_project if it requires a project context.
  _project_setup

  if [ -n "${p["setup_error"]}" ]; then
    project_show_error "Project-cmd setup error."
    return 1
  fi

  local command_file="${p["_script_path"]}/commands/${command}.sh"
  if [ -f "$command_file" ]; then
    source "$command_file"
  else
    if [ -n "$command" ]; then
      project_show_error "Unknown command \"${TEXT_YELLOW}${command}${TEXT_RESET}\"."
    fi

    # If no valid command was given, show usage.
    echo "Usage: project [-t TAG] COMMAND"
    echo ""
    echo "Options:"
    echo "  -p PROJECT    Run this command for the project PROJECT even if it's on in the current work dir."
    echo "  -t TAG        Run this command for the project tag TAG."
    echo ""
    echo "Project commands:"
    echo "  These can be executed when in a project directory or when the project is set via the -p option."
    echo ""
    echo "  compare_with_project Compare/diff a file from this project with the same relative path in another project."
    echo "                       Usage: compare_with_project FILE_OR_PATH PROJECT_NAME"
    echo "  get_env_value        Retrieve the value of an environment variable. PROJECT_NAME defaults to the current project"
    echo "                       Usage: get_env_value VARIABLE_NAME [PROJECT_NAME]"
    echo "  restart              Shorthand for 'project run restart'. See the 'run' command."
    echo "  run                  Executes a script for the current project."
    echo "                       Usage: run SCRIPT_NAME [SCRIPT_ARGS] ..."
    echo "  start                Shorthand for 'project run start'. See the 'run' command."
    echo "  stop                 Shorthand for 'project run stop'. See the 'run' command."
    echo ""
    echo ""
    echo "Global commands:"
    echo "  These can executed independent of the current work dir."
    echo ""
    echo "  add                  Add a project."
    echo "                       Usage: add [PROJECT_NAME] [PROJECT_PATH]"
    echo "  cd                   Change to another project. Shorthand for 'cd /path/to/my/project'."
    echo "                       Usage: cd PROJECT_NAME"
    echo "  create               Create and add a project based on a project template."
    echo "                       Usage: create PROJECT_TEMPLATE NAME PROJECT_PATH"
    echo "  end                  Stops docker."
    echo "  global_run           Executes one of the built-in global scripts."
    echo "  list                 List all registered project and their state."
    echo "  build_docker_images  Builds one ore more docker images located in a common base path."
    echo "                       Usage: build_docker_images IMAGES BASE_PATH ENV"
    echo "  ps                   A shorthand for docker ps -a."
    echo "  remove               Removes a project by name. This only removes the project registration and does not delete project files."
    echo "                       Usage: remove PROJECT_NAME"
    return 0
  fi
}

_project_cmd "$@"
