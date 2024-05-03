#!/bin/bash
# Project-cmd command script.

command="$1"
shift

if [ -n "$command" ]; then
  _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"

  case $command in

    compose_update)
      if project_has_script "$PROJECT_NAME" "docker_compose_update"; then
        _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"
        _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "docker_compose_update" "$@"
      else
        source "${p["_script_path"]}/_global-scripts.sh"
        project_run_global_script "docker_compose_update" "$@"
      fi
      ;;

  esac;

else
    echo "Commands related to docker."
    echo "Usage: docker COMMAND"
    echo "Commands:"
    echo "  update_compose:  Create/update the docker-compose file for this project based on the configured template in .env."
fi
