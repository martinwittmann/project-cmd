#!/bin/bash

_project_complete_project_name() {
  local names
  names="$(_project_get_project_names)"
  COMPREPLY=($(compgen -W "${names[*]}" -- "$1"))
}
