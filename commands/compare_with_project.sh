#!/bin/bash

relative_filename="$1"
other_project_name="$2"

if ! project_path="$(_project_get_project_path)"; then
  return 1
fi

if ! project_name="$(_project_get_project_name "$project_path")"; then
  return 1
fi

_project_setup_project "$project_name"
global_scripts="${p["_script_path"]}/_global-scripts.sh"
source "$global_scripts"
project_run_global_script compare_with_project "$relative_filename" "$other_project_name"
