#!/bin/bash
# Project-cmd command script.
# Available variables:
# - $project_name
# - $project_tag

relative_filename="$1"
other_project_name="$2"

_project_setup_project "$project_name" "$project_tag"
source "${p["_script_path"]}/_global-scripts.sh"
project_run_global_script compare_with_project "$relative_filename" "$other_project_name"
