#!/bin/bash

if ! project_is_production; then
  project_start_docker
  project -p "$PROJECT_PROXY_PROJECT_NAME" start
fi

# Automatically update php.env to reflect the current .env values.
project_run_global_script update_php_env

project_run_global_script start
