#!/bin/bash
# Project-cmd command script.

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  script_name="$1"
  shift

  # Since some global scripts require a project we always try to set up the current project.
  # This call might fail, but we can ignore it here since it's possible global_run
  # might have been called outside a project.
  PROJECT_PATH=$(_project_get_project_path);

  # If we found a project path but can't find a name, something is wrong.
  if [ -N "$PROJECT_PATH" ] && ! PROJECT_NAME=$(_project_get_project_name "$PROJECT_PATH"); then
    project_show_error "Project \"${TEXT_YELLOW}${project_name}${TEXT_RESET}\" not found."
    return 1
  fi

  _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"

  source "${p["_script_path"]}/_global-scripts.sh"
  project_run_global_script "$script_name" "$@"
)
