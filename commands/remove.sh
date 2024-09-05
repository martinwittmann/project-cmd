#!/bin/bash
# Project-cmd command script.

project_name_to_remove="$1"
if [ -z "$project_name_to_remove" ]; then
  project_show_error "You need to provide a project name."
  return 1
fi

if ! project_path="$(_project_get_project_path_by_name "$project_name_to_remove")"; then
  project_show_error "Project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" not found."
  return 1
fi

if [ ! -d "$project_path" ]; then
  project_show_warning "Project path \"${TEXT_YELLOW}${project_path}${TEXT_RESET}\" does not exist."
fi

unset PROJECTS["$project_path"]
project_removed=0
if ! unlink "${PROJECT_PROJECT_CMD_CONFIG_PATH}/projects.d/$project_name_to_remove"; then
  project_show_warning "Could not unlink \"${TEXT_YELLOW}${symlink}${TEXT_RESET}\". Trying with sudo.."
  if sudo unlink "${PROJECT_PROJECT_CMD_CONFIG_PATH}/projects.d/$project_name_to_remove"; then
    project_removed=1
  fi
else
  project_removed=1
fi

if [ $project_removed ]; then
  project_show_success "Removed project \"${TEXT_YELLOW}${project_name_to_remove}${TEXT_RESET}\"."
else
  project_show_error "Could not remove project \"${TEXT_YELLOW}${project_name_to_remove}${TEXT_RESET}\"."
fi
