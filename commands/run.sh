#!/bin/bash

if ! project_path="$(_project_get_project_path)"; then
  return 1
fi

if ! project_name="$(_project_get_project_name "$project_path")"; then
  return 1
fi

script_name="$1"
shift
_project_setup_project "$project_name"
_project_run_script "$project_name" "$project_path" "$script_name" "$@"
