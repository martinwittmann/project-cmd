#!/bin/bash

if [ -z "$PROJECT_TAG" ]; then
  project_run_global_script mysql
else
  project_run_global_script mysql_root
fi
