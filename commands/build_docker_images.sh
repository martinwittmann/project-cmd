#!/bin/bash

# Executing everthing in a subshell to not pollute the parent shell's variables.
(
  dirnames="$1"
  basepath="${2:-${p["_script_path"]}/docker/${dirname}}"
  env="${3}"
  image_prefix="${4}"
  project_build_docker_images "$dirnames" "$basepath" "$env" "$image_prefix"
)
