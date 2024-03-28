#!/bin/bash

if ! project_path="$(_project_get_project_path)"; then
  project_show_error "No project found in current dir or any parent dirs."
  return 1
fi

if ! project_name="$(_project_get_project_name "$project_path")"; then
  return 1
fi

_project_setup_project "$project_name"
_project_run_script "$project_name" "$project_path" "stop" "$@"