#!/usr/bin/env bash

_pcd_completions()
{
  incomplete="${COMP_WORDS[COMP_CWORD]}"
  projects=`project projects --only-ids`
  COMPREPLY=( $(compgen -W "${projects}" -- ${incomplete}) )
}
complete -F _pcd_completions pcd
