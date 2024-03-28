#!/bin/bash

declare -A PROJECT_PROJECTS
declare -A p
p["_script_path"]="$(realpath "${BASH_SOURCE[0]}" | xargs dirname)"
declare -A p_projects

_project_cmd() {
  SETUP_ERROR=""
  # The path of project.sh.
  source "${p["_script_path"]}/_setup.sh"

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

  # This sets up project-cmd, but not a project.
  _project_setup "$project_name" "$project_tag"

  if [ -n "${p["project_path"]}" ]; then
    project_name="${p["project_name"]}"
    project_path="${p["project_path"]}"
  fi

  if [ -n "$SETUP_ERROR" ]; then
    project_show_error "Project-cmd setup error."
    return 1
  fi

  local command_file="${p["_script_path"]}/commands/${command}.sh"
  if [ -f "$command_file" ]; then
    source "$command_file"
  else
    if [ -n "$command" ]; then
      project_show_error "Unknown command \"${p["_text_yellow"]}${command}${p["_text_reset"]}\"."
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
    echo "  compare_with_project   Compare/diff a file from this project with the same relative path in another project."
    echo "                         Usage: compare_with_project FILE_OR_PATH PROJECT_NAME"
    echo ""
    echo "  get_env_value          Retrieve the value of an environment variable. PROJECT_NAME defaults to the current project".
    echo "                         Usage: get_env_value VARIABLE_NAME [PROJECT_NAME]"

    echo ""
    echo ""
    echo "Global commands:"
    echo "  These can executed independent of the current work dir."
    echo ""
    echo "  add                    Add a project."
    echo "                         Usage: add [PROJECT_NAME] [PROJECT_PATH]"
    echo ""
    echo "  create                 Create and add a project based on a project template."
    echo "                         Usage: create PROJECT_TEMPLATE NAME PROJECT_PATH"
    echo ""
    echo "  end                    Stops docker."
    echo "  list                   List all registered project and their state."
    echo ""
    echo "  build_docker_images    Builds one ore more docker images located in a common base path."
    echo "                         Arguments:"
    echo "                           IMAGES:         Names of directories inside BASE_PATH that contain docker files,"
    echo "                                           separated by ';'. These will also be used as image names."
    echo "                                           Example: If IMAGES has a value of \"hello-world;another_image\""
    echo "                                                    then the following paths will be used as PATH for docker build:"
    echo "                                                    - BASE_PATH/hello-world"
    echo "                                                    - BASE_PATH/another_image"
    echo "                           BASE_PATH:      Used as path prefix for each directory name in IMAGES. This"
    echo "                                           defaults to [path-to-project-cmd]/docker"
    echo "                           [ENV]:          An optional global environment name like dev, prod,... Each"
    echo "                                           Dockerfile will get the build argument APP_ENV with this value."
    echo "                                           Additionally this will be used as tag for the built image if set."
    echo "                           [IMAGE_PREFIX]: This will be used as prefix for each image name if set."
    echo "                         Usage: build_docker_images IMAGES BASE_PATH ENV"
    echo ""
    echo "  ps                     A shorthand for docker ps -a."
    echo "  remove                 Removes a project by name. This only removes the project registration and does not delete project files."
    echo "                         Usage: remove PROJECT_NAME"
    return 0
  fi
}

_project_cmd "$@"
