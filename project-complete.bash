#!/bin/bash
_project_autocomplete() {
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