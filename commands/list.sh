#!/bin/bash

echo "The following projects were found:"
for project_path in "${!p_projects[@]}"; do
  _project_get_project_status "${p_projects["$project_path"]}" "$project_path" "short"
done

