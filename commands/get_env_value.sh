#!/bin/bash

variable_name="$1"
project_name="${2:-$PROJECT_NAME}"
_project_get_env_value "$project_name" "$variable_name"
