#!/bin/bash
_project_autocomplete() {
  local __PROJECT_SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}" | xargs dirname)
  PROJECT_PROJECTS_PATH=`realpath ~/.projects`
  source "$__PROJECT_SCRIPT_PATH/_functions.sh"

  declare -Ag PROJECT_PROJECTS
  _project_populate_projects_array

  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}

  case $prev in

    "project" | "p")
      # No project command was typed, list the available commands.
      local options=("cd" "list" "run" "status" "stt" "dd" "sdf" "ff" "gdf" "sdfd" "zhfd")
      COMPREPLY=($(compgen -W "${options[*]}" -- $cur))
      ;;

    "cd")
      _project_cd_autocomplete "$cur"
      ;;

    "run")
      _project_run_autocomplete "$cur"
      ;;
  esac
}

_project_cd_autocomplete() {
  local names=$(_project_get_project_names)
  COMPREPLY=($(compgen -W "${names[*]}" -- "$1"))
}

_project_run_autocomplete() {
  PROJECT_PATH=`_project_get_project_path`

  if [ -z "$PROJECT_PATH" ]; then
    echo ""
    project_show_error "This is not a project directory."
    return 1
  fi

  PROJECT_NAME="${PROJECT_PROJECTS[$PROJECT_PATH]}"
  _project_assert_project_exists "$PROJECT_NAME" "$PROJECT_PATH"

  local cur="$1"
  local scripts_dir="$PROJECT_PATH/.project/scripts"

  if [ ! -d $scripts_dir ]; then
    echo ""
    project_show_error "Scripts dir not found for project."
    return 1
  fi

  local scripts=()
  for script in $PROJECT_PATH/.project/scripts/*.sh; do
    if [ -f "$script" ]; then
      scripts+=($(basename $script|sed -e 's/\.sh$//'))
    fi
  done

  COMPREPLY=($(compgen -W "${scripts[*]}" -- $cur))
}