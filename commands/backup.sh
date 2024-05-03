#!/bin/bash
# Project-cmd command script.

command="$1"
shift

if [ -n "$command" ]; then
  if [ -z "$PROJECT_NAME" ]; then
    project_show_error "Can't find a project in the current path."
    return 1
  fi

  # Allow scripts to override the default backup scripts.
  if project_has_script "$PROJECT_NAME" "backup_${command}"; then
    _project_setup_project "$PROJECT_NAME" "$PROJECT_TAG"
    _project_run_script "$PROJECT_NAME" "$PROJECT_PATH" "backup_${command}" "$@"
  else
    # Execute our global scripts which should suffice for most projects.
    case $command in
      create)
        project_run_global_script "create_backup_for_project" "$PROJECT_NAME"
        ;;

      setup)
        project_run_global_script "set_up_backups" "borg" "$PROJECT_NAME"
        ;;

      list)
        project_run_global_script "list_backups_for_project" "$PROJECT_NAME"
        ;;

      mount)
        project_run_global_script "mount_project_backup" "$PROJECT_NAME" "$@"
        ;;

      rotate)
        project_run_global_script "rotate_backups_for_project" "$PROJECT_NAME"
        ;;

      ssh)
        project_run_global_script "ssh_into_backup" "$PROJECT_NAME"
        ;;

      umount)
        project_run_global_script "umount_project_backup" "$PROJECT_NAME"
        ;;

    esac;

  fi

else
    echo "Do backups via borg backup."
    echo "Usage: backup COMMAND"
    echo "Commands:"
    echo "  create:         Creates a backup for this project."
    echo "  init:           Initializes a borg repository for this project. This requires several values in the .env file to be set up. See the backup section in .env."
    echo "  list:           Lists the backups that have been created for this project."
    echo "  mount:          Mounts the given archive name to the backup mount point. See PROJECT_BACKUPS_MOUNT_POINT in .env."
    echo "  rotate:         Applies the configured backup rotation scheme as defined in .env."
    echo "  ssh:            Logs into the backup server via ssh."
    echo "  umount:         Unmounts the given archive name from the backup mount point."
    echo ""
    echo "You can override these scripts by creating .project/scripts/backup_[backup_command].sh script that will be executed instead of the default implementations like other project script when executing 'project backup [command]'."
fi
