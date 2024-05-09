#!/bin/bash
# Project-cmd command script.

if [ "$#" -gt 2 ]; then
  template="$1"
  new_project_name="$2"
  new_project_path="$3"
  shift 3
  project_create_from_template "$template" "$new_project_name" "$new_project_path" "$@"
else
  templates_dir="${p['script_path']}/project-templates"
  echo "Create project from a template."
  echo "Usage: create TEMPLATE PROJECT_NAME PROJECT_PATH [ENV_VARS]"
  echo "Arguments:"
  echo "  TEMPLATE:      A project template corresponding to a dir name in $templates_dir."
  echo "  PROJECT_NAME:  The projects name/id. Should only consist of lowercase alphanumeric characters and underscores (_)."
  echo "  PROJECT_PATH:  The path where the project will be created. Will be created if it does not exist."
  echo "  [ENV_VARS]:    Pairs of additional arguments will be treated as name and value of environment variables and will be written to the project's .env file."
fi
