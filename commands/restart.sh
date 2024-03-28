#!/bin/bash

_project_setup_project "$project_name"
_project_run_script "$project_name" "$project_path" "restart" "$@"
