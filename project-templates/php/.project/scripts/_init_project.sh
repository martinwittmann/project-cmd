#!/bin/bash

_init_project() {
  project run update_docker_compose
  project run add_to_proxy
}

_init_project
