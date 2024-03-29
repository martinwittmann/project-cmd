#!/bin/bash
# Project-cmd command script.

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  if [ "$#" -gt 1 ]; then
    dirnames="$1"
    basepath="${2:-${p["_script_path"]}/docker/${dirname}}"
    env="${3}"
    image_prefix="${4}"
    project_build_docker_images "$dirnames" "$basepath" "$env" "$image_prefix"
  else
    echo "Usage: build_docker_images IMAGES BASE_PATH ENV"
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
