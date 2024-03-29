#!/bin/bash

_project_complete_project_name() {
  local names
  names="$(_project_get_project_names)"
  COMPREPLY=($(compgen -W "${names[*]}" -- "$1"))
}

_project_complete_script_name() {
  local project_path
  project_path=$(_project_get_project_path)

  # TODO Handle -p option to complete script of another project.
  # Currently the scripts of the active project are completed, regardless of -p.

  if [ -z "$project_path" ]; then
    return 1
  fi

  local cur="$1"
  local scripts_dir="$project_path/.project/scripts"

  if [ ! -d "$scripts_dir" ]; then
    project_show_error "Scripts dir not found for project."
    return 1
  fi

  local scripts=()
  for script in "$scripts_dir"/*.sh; do
    if [ -f "$script" ]; then
      scripts+=("$(basename "$script"|sed -e 's/\.sh$//')")
    fi
  done

  COMPREPLY=($(compgen -W "${scripts[*]}" -- $cur))
}


_project_run_autocomplete() {
  local project_path
  project_path=$(_project_get_project_path)

  if [ -z "$project_path" ]; then
    return 1
  fi

  local cur="$1"
  local scripts_dir="$project_path/.project/scripts"

  if [ ! -d $scripts_dir ]; then
    echo ""
    project_show_error "Scripts dir not found for project."
    return 1
  fi

  local scripts=()
  for script in "$scripts_dir"/*.sh; do
    if [ -f "$script" ]; then
      scripts+=($(basename $script|sed -e 's/\.sh$//'))
    fi
  done

  COMPREPLY=($(compgen -W "${scripts[*]}" -- $cur))
}

_project_complete_tag_name() {
  local cur="$1"
  local project_path
  project_path=$(_project_get_project_path)

  local project_name
  project_name=$(_project_get_project_name "$project_path")

  local env_file
  env_file="$project_path/.env"

  local tags
  tags=$(_project_get_env_value "$project_name" PROJECT_TAGS)
  IFS=',' read -r -a tags_list <<< "$tags"
  COMPREPLY=($(compgen -W "${tags_list[*]}" -- $cur))
}
