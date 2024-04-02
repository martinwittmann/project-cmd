#!/bin/bash
# Project-cmd command script.

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  _project_setup_project "$PROJECT_NAME"
  script_filename=$(_project_get_script_path "$PROJECT_PATH" "stop")

  if [ -f "$script_filename" ]; then
    # If the project defines a custom stop script, use it.
    _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "stop" "$@"
  else
    # Default to our global script.
    source "${p["_script_path"]}/_global-scripts.sh"
    _project_global_script_stop
  fi
)