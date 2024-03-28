#!/bin/bash

_proxy_update_docker_compose() {
  project_render_template "${p["project_name"]}:docker-compose/$PROJECT_ENV"\
   environment "\${PROJECT_ENV}"\
   container_name "\${PROJECT_CONTAINER_NAME}"\
   container_uid "\${PROJECT_CONTAINER_UID}"\
   db_container_name "\${PROJECT_DB_CONTAINER_NAME}"\
   db_root_password "\${PROJECT_DB_ROOT_PASSWORD}"\
   db_name "\${PROJECT_DB_NAME}"\
   db_user "\${PROJECT_DB_USER}"\
   db_password "\${PROJECT_DB_PASSWORD}"\
   project_path_in_container "\${PROJECT_PATH_IN_CONTAINER}"\
   network_name "$PROJECT_DOCKER_NETWORK_NAME"\
  > "${p["project_path"]}/docker-compose.$PROJECT_ENV.yml"
}

_proxy_update_docker_compose
