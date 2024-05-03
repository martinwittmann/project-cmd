#!/bin/bash

# Bootstrapping.
declare -A p
p["_script_path"]="$(realpath "${BASH_SOURCE[0]}" | xargs dirname)"
source "${p["_script_path"]}/_setup.sh"

_project_autocomplete() {
  source "${p["_script_path"]}/_setup.sh"

  # This sets up project-cmd, but not a project.
  _project_setup


  # Shift the options out
  shift $((OPTIND - 1))

  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local prevprev=${COMP_WORDS[COMP_CWORD-2]}

  declare -a commands=()
  _project_get_available_commands commands

  local completions_base="${p["_script_path"]}/completions"
  source "$completions_base/_global.sh"

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

    backup)
      local backup_commands=("create" "setup" "list" "mount" "rotate" "ssh" "umount")
      COMPREPLY=($(compgen -W "${backup_commands[*]}" -- $cur))
      ;;

    cd)
      if [ -f "$completions_base/cd.sh" ]; then
        source "$completions_base/cd.sh"
      fi
      ;;

    docker)
      local docker_commands=("compose_update")
      COMPREPLY=($(compgen -W "${docker_commands[*]}" -- $cur))
      ;;

    remove)
      if [ -f "$completions_base/remove.sh" ]; then
        source "$completions_base/remove.sh"
      fi
      ;;

    run)
      if [ -f "$completions_base/run.sh" ]; then
        source "$completions_base/run.sh"
      fi
      ;;

  esac
}


