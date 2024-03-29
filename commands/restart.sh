#!/bin/bash

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  _project_setup_project "$project_name"
  _project_run_script "$project_name" "$project_path" "restart" "$@"
)
