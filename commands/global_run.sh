#!/bin/bash
# Project-cmd command script.
# Available variables:
# - $project_name
# - $project_tag

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  script_name="$1"
  shift
  if [ ! -z "$project_name" ]; then
    # Since some global scripts require a project we always set it up if possible.
    _project_setup_project "$project_name" "$project_tag"
  fi

  source "${p["_script_path"]}/_global-scripts.sh"
  project_run_global_script "$script_name" "$@"
)
