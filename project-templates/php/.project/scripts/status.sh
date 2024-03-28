#!/bin/bash

# This can be one of:
# - "services": List all container names and their respective status.
# - "summary":  Shows whether or not all services are up/down.
# - "short":    Shows only up/down.
status_format="${1:-short}"
_project_get_project_status_via_docker_compose "${p["project_name"]}" "$status_format"
