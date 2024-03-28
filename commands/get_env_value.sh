#!/bin/bash

variable_name="$1"
project_name="${2:-${p["project_name"]}}"
_project_get_env_value "$project_name" "$variable_name"
