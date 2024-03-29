#!/bin/bash

project_name="$1"
if [ -z "$project_name" ]; then
  project_show_error "Missing argument [project_name]."
  return 1
fi

if ! project_path=$(_project_get_project_path_by_name "$project_name"); then
  project_show_error "Project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" not found."
  return 1
fi
cd "$project_path"
project_show_message "You're now in project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" $project_path."
