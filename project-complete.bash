#!/bin/bash
_project_autocomplete() {
  local __PROJECT_SCRIPT_PATH=`realpath "${BASH_SOURCE[0]}" | xargs dirname`
  PROJECT_PROJECTS_PATH=`realpath ~/.projects`
  source "$__PROJECT_SCRIPT_PATH/_functions.sh"

  declare -Ag PROJECT_PROJECTS
  _project_populate_projects_array

  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}

  case $prev in

    "project" | "p")
      # No project command was typed, list the available commands.
      local options=("cd" "list" "run" "status")
      COMPREPLY=(`compgen -W "${options[*]}" -- $cur`)
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
  local names=`_project_get_project_names`
  COMPREPLY=(`compgen -W "${names[*]}" -- "$1"`)
}

_project_run_autocomplete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local scripts_dir="./scripts"
  local scripts=$(ls "$scripts_dir" | sed -e 's/\.sh$//')


    # Complete script names
    if [ $COMP_CWORD -eq 1 ]; then
      COMPREPLY=$(compgen -W "$scripts" -- $cur)
      echo $COMPREPLY
      return 0
    else
      FUNCTION_NAME="_project_complete_${COMP_WORDS[1]}"
      if [ "$(type -t $FUNCTION_NAME)"]; then
        COMPREPLY=$()
      fi

      COMPREPLY=()
      cur_word="${COMP_WORDS[COMP_CWORD]}"
      prev_word="${COMP_WORDS[COMP_CWORD-1]}"

      if [[ $(type -t foo) == function ]]; then
        COMPREPLY+=$("$FUNCTION_NAME")
      fi
    fi
  }