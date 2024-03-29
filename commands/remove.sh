#!/bin/bash
# Project-cmd command script.

project_name_to_remove="$1"
if [ -z "$project_name_to_remove" ]; then
  project_show_error "You need to provide a project name."
  return 1
fi

if ! project_path="$(_project_get_project_path_by_name "$project_name_to_remove")" || [ ! -d "$project_path" ]; then
  project_show_error "Project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" not found."
  return 1
fi

sudo unlink "/etc/project-cmd/projects.d/$project_name_to_remove"

