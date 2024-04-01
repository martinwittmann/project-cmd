#!/bin/bash

_init_project() {
  project run docker_compose_update
  project run add_to_proxy
}

_init_project
