#!/bin/bash
# Project-cmd command script.
# Available variables:
# - $project_name
# - $project_tag

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  _project_setup_project "$project_name" "$project_tag"
  _project_run_script "$project_name" "$project_path" "start" "$@"

  if [ -n "$PROJECT_URL" ]; then
    _project_print_url "$PROJECT_URL"
  fi
)

