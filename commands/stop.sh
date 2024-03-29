#!/bin/bash
# Project-cmd command script.

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  _project_setup_project "$PROJECT_NAME"
  _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "stop" "$@"
)