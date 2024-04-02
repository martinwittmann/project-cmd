#!/bin/bash
# Project-cmd command script.

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"
  script_filename=$(_project_get_script_path "$PROJECT_PATH" "start")

  if [ -f "$script_filename" ]; then
    # If the project defines a custom start script, use it.
    _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "start" "$@"
  else
    # Default to our global script.
    source "${p["_script_path"]}/_global-scripts.sh"
    _project_global_script_start
  fi

  if [ -n "$PROJECT_URL" ]; then
    _project_print_url "$PROJECT_URL"
  fi
)

