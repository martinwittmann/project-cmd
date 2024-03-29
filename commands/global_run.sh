#!/bin/bash
# Project-cmd command script.

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  script_name="$1"
  shift
  if [ ! -z "$PROJECT_NAME" ]; then
    # Since some global scripts require a project we always set it up if possible.
    _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"
  fi

  source "${p["_script_path"]}/_global-scripts.sh"
  project_run_global_script "$script_name" "$@"
)
