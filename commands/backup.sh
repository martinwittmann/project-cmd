#!/bin/bash
# Project-cmd command script.
# Available variables:
# - $project_name
# - $project_tag

command="$1"

if [ -n "$command" ]; then
else
    echo "Do backups via borg backup."
    echo "Usage: backup COMMAND"
    echo "Commands:"
    echo "  init:           Initializes a borg repository for this project."
    echo "  create:         Creates a backup for this project."

    echo "  BASE_PATH:      Used as path prefix for each directory name in IMAGES."
    echo "  [ENV]:          An optional global environment name like dev, prod,... Each"
    echo "                  Dockerfile will get the build argument APP_ENV with this value."
    echo "                  Additionally this will be used as tag for the built image if set."
    echo "  [IMAGE_PREFIX]: This will be used as prefix for each image name if set."
fi
