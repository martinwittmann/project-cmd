#!/bin/bash
# Project-cmd command script.

command="$1"
shift

if [ -n "$command" ]; then
  _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"

  case $command in

    compose_update)
      if project_has_script "$PROJECT_NAME" "docker_compose_update"; then
        _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "docker_compose_update" "$@"
      else
        source "${p["_script_path"]}/_global-scripts.sh"
        project_run_global_script "docker_compose_update" "$@"
      fi
      ;;

    images_build)
      (
        if [ "$#" -gt 1 ]; then
          dirnames="$1"
          basepath="${2:-${p["_script_path"]}/docker/${dirname}}"
          env="${3}"
          image_prefix="${4}"
          project_docker_images_build "$dirnames" "$basepath" "$env" "$image_prefix"
        else
          echo "Usage: docker_images_build IMAGES BASE_PATH ENV"
          echo "Arguments:"
          echo "  IMAGES:         Names of directories inside BASE_PATH that contain docker files,"
          echo "                  separated by ';'. These will also be used as image names."
          echo "                  Example: If IMAGES has a value of \"hello-world;another_image\""
          echo "                           then the following paths will be used as PATH for docker build:"
          echo "                           - BASE_PATH/hello-world"
          echo "                           - BASE_PATH/another_image"
          echo "  BASE_PATH:      Used as path prefix for each directory name in IMAGES."
          echo "  [ENV]:          An optional global environment name like dev, prod,... Each"
          echo "                  Dockerfile will get the build argument APP_ENV with this value."
          echo "                  Additionally this will be used as tag for the built image if set."
          echo "  [IMAGE_PREFIX]: This will be used as prefix for each image name if set."
        fi
      )
      ;;


    rebuild_containers)
      ;;

  esac;

else
    echo "Commands related to docker."
    echo "Usage: docker COMMAND"
    echo "Commands:"
    echo "  update_compose:  Create/update the docker-compose file for this project based on the configured template in .env."
fi
