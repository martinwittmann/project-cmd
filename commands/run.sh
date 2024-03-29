#!/bin/bash
# Project-cmd command script.

# Executing everything in a subshell to not pollute the parent shell's variables.
(
  script_name="$1"
  if [ -n "$script_name" ]; then
    shift
    _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"
    _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "$script_name" "$@"
  else
    echo "Run a script in the current project."
    echo "Usage: run SCRIPT_NAME"
    echo ""
    echo "Arguments:"
    echo "  SCRIPT_NAME:    The name (basename) of the project script to be executed."
    echo "                  Example: run \"my_script\" will execute .project/scripts/my_script.sh"
  fi
)
