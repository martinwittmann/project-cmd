#!/bin/bash

project_name="$1"
if [ -z "$project_name" ]; then
  project_show_error "You need to provide a project name."
  return 1
fi

if ! project_path="$(_project_get_project_path_by_name "$project_name")"; then
  return 1
fi

project_name="$(_project_get_project_name "$project_path" "0")"
if [ -z "$project_name" ]; then
  project_show_error "Project \"${p["_text_yellow"]}${project_name}${p["_text_reset"]}\" not found."
  return 1
fi

sudo unlink "/etc/project-cmd/projects.d/$project_name"

