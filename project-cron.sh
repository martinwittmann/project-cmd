#!/bin/bash -l

cron_script_dir="$(realpath "${BASH_SOURCE[0]}" | xargs dirname)"
SHELL_IS_CRON=1
source "$cron_script_dir/project.sh"
