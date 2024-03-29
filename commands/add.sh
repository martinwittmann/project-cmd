#!/bin/bash
# Project-cmd command script.
# Available variables:
# - $project_name
# - $project_tag

new_project_name="$1"
quiet="$2"
project_add_project "$new_project_name" "$quiet"