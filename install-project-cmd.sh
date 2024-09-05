#!/bin/bash

install_project_cmd() {
  local script_path
  script_path="$(realpath "${BASH_SOURCE[0]}" | xargs dirname)"
  source "${script_path}/.env"
  echo "${PROJECT_PROJECT_CMD_CONFIG_PATH}"
  mkdir "${PROJECT_PROJECT_CMD_CONFIG_PATH}/projects.d" -p
}

install_project_cmd