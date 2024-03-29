#!/bin/bash
# Project-cmd command script.
# Available variables:
# - $project_name
# - $project_tag

echo "The following projects were found:"
for project_path in "${!PROJECTS[@]}"; do
  _project_get_project_status "${PROJECTS["$project_path"]}" "$project_path" "short"
done

