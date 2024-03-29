#!/bin/bash
# Project-cmd command script.
# Available variables:
# - $project_name
# - $project_tag

new_project_name="$1"
if [ -z "$new_project_name" ]; then
  project_show_error "Missing argument [project_name]."
  return 1
fi

if ! project_path=$(_project_get_project_path_by_name "$new_project_name"); then
  project_show_error "Project \"${TEXT_YELLOW}${new_project_name}${TEXT_RESET}\" not found."
  return 1
fi
cd "$project_path"
project_show_message "You're now in project \"${TEXT_YELLOW}${new_project_name}${TEXT_RESET}\"."
