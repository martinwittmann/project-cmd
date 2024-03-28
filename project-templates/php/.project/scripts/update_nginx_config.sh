#!/bin/bash

project_run_global_script "create_nginx_config_for_project" "${p["project_name"]}" "$PROJECT_NGINX_TEMPLATE" "$PROJECT_PROXY_PROJECT_NAME" 1

project_run_global_script "create_nginx_log_files"