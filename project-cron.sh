#!/bin/bash -l

# When executing project-cmd via cron, this file is supposed to be used instead
# of project.sh.
# This way project-cmd will know it is running in a non-interactive shell.

cron_script_dir="$(realpath "${BASH_SOURCE[0]}" | xargs dirname)"
SHELL_IS_CRON=1
source "$cron_script_dir/project.sh"
