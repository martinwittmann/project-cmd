#!/bin/bash
declare -A PROJECT_PROJECTS

# TODO This file needs quite a bit of clean up.

_project_autocomplete() {
  local project_script_path
  project_script_path=$(realpath "${BASH_SOURCE[0]}" | xargs dirname)
  #PROJECT_PROJECTS_PATH="/etc/project-cmd/projects.d"
  #. "$project_script_path/_functions.sh"

  #_project_populate_projects_array

  . "$project_script_path/_setup.sh"

  # This sets up project-cmd, but not a project.
  _project_setup "$project_name" "$project_tag"

  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local prevprev=${COMP_WORDS[COMP_CWORD-2]}

  local commands=("add" "build_docker_images" "cd" "compare_with_project" "end" "list" "remove" "restart" "run" "start" "stop" "tag")

  case $prevprev in 
    tag)
      COMPREPLY=($(compgen -W "${commands[*]}" -- $cur))
      ;;
  esac

  case $prev in

    project | p)
      # No project command was typed, list the available commands.
      COMPREPLY=($(compgen -W "${commands[*]}" -- $cur))
      ;;

    cd)
      _project_autocomplete_project_name "$cur"
      ;;

    remove)
      _project_autocomplete_project_name "$cur"
      ;;

    run)
      _project_run_autocomplete "$cur"
      ;;

    tag)
      _project_tag_autocomplete "$cur"
      ;;
  esac
}

_project_autocomplete_project_name() {
  local names
  names=$(_project_get_project_names)
  COMPREPLY=($(compgen -W "${names[*]}" -- "$1"))
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

_project_tag_autocomplete() {
  local cur="$1"
  local project_path
  project_path=$(_project_get_project_path)
  local env_file
  env_file="$project_path/.env"
  local tags
  tags=$(grep "^PROJECT_TAGS=" "$env_file" | cut -d'=' -f2)
  IFS=',' read -r -a tags_list <<< "$tags"
  COMPREPLY=($(compgen -W "${tags_list[*]}" -- $cur))
}
