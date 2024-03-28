#!/bin/bash

project_name="$1"
if [ -z "$project_name" ]; then
  project_show_error "Missing argument [project_name]."
  return 1
fi

if ! project_path=$(_project_get_project_path_by_name "$project_name"); then
  project_show_error "Project \"${p["_text_yellow"]}${project_name}${p["_text_reset"]}\" not found."
  return 1
fi
cd "$project_path"
project_show_message "You're now in project \"${p["_text_yellow"]}${project_name}${p["_text_reset"]}\" $project_path."
