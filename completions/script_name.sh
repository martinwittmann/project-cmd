#!/bin/bash

_project_complete_script_name() {
  local project_path
  project_path="$(_project_get_project_path)"

  if [ -z "$project_path" ]; then
    return 1
  fi

  local cur="$1"
  local scripts_dir="$project_path/.project/scripts"

  if [ ! -d "$scripts_dir" ]; then
    echo ""
    project_show_error "Scripts dir not found for project."
    return 1
  fi

  local scripts=()
  for script in "$scripts_dir"/*.sh; do
    if [ -f "$script" ]; then
      scripts+=("$(basename "$script"|sed -e 's/\.sh$//')")
    fi
  done

  COMPREPLY=("$(compgen -W "${scripts[*]}" -- $cur)")
}
