#!/bin/bash

if ! project_is_production; then
  project_start_docker
  _project_run_script "$PROJECT_PROXY_PROJECT_NAME" "$(_project_get_project_path_by_name "$PROJECT_PROXY_PROJECT_NAME")" start
fi

project_run_global_script "update_php_env"

project_run_global_script start
