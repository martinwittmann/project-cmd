#!/bin/bash
# Project-cmd command script.

template="$1"
new_project_name="$2"
new_project_path="$3"
project_create_from_template "$template" "$new_project_name" "$new_project_path"
