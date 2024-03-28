# Project-cmd: Command line utilities for managing software projects.
Project cmd enables a standardized, opinionated and mostly technology-agnostic way of managing software projects.

Think of project-cmd as cli tool being a light-weight mashup of devcontainer.json that can also work without docker + vscode and npx that works for any language and in any (sub)directory of the project.
For simple setups this can also be used to deploy apps.

- Easy docker (compose) integration
- Start, stop, restart each project in the same way (p start) regardless of the tech stack 
- Run predefined (global) and custom scripts from any (sub)directory in the project: p run [script_name] - including bash completion for available scripts
- List registered projects with their name, path and status (e.g. up, down)
- Quickly change to any project directory with "p cd [project-name]"
- Set up + configure your project via .env files
- You can use env variables in your custom scripts - no setup needed
- No complicated magic - it's just a light-weight wrapper for bash scripts


# Use-case examples

## Project setup
Create a directory for your project or change into an existing project.

Create a .env file:
  ```
  PROJECT_NAME=my_project
  PROJECT_ENV=dev

  # Recommended if you use docker:
  PROJECT_USE_DOCKER=1
  PROJECT_CONTAINER_NAME=$PROJECT_NAME
  # Required for some global scripts and quite handy in docker compose files.
  PROJECT_PATH_IN_CONTAINER=/app
  ```

Create a docker-compose.dev.yml if you want to use docker:
  ```
  services:
    app:
      container_name: ${PROJECT_CONTAINER_NAME}
      build:
        context: ./.project/docker/app
        # Of course you can use your custom directory structure.
      volumes:
        - ./:${PROJECT_PATH_IN_CONTAINER}
      restart: always
      user: www-data
      extra_hosts:
        - host.docker.internal:host-gateway
      env_file:
        # Makes all values of .env available as environment variables in this container.
        - .env
  ```

Create a .project/scripts directory and add scripts you need:
  E.g.: .project/scripts/start.sh:
  ```
  # If you're using docker then this will run docker compose with docker-compose.[PROJECT_ENV].yml
  project_run_global_script start

  # TODO Add / modify to according to your needs.
  ```

## Starting, stopping, restarting a project - if your project needs it
- To start a project execute `p start` anywhere inside the project's path.
- This is just a wrapper for `p run start` which in turn executes .project/scripts/start.sh.

- To stop a project, execute `p stop`.
- Restart `p restart` - you get it.

## Additional / custom scripts
Create .project/scripts/npm.sh:
  ```
  #!/bin/bash

  # Example: Run npm in a node container
    docker run \
    -it \
    --workdir "$PROJECT_PATH_IN_CONTAINER/path/to/npm" \
    --name "${PROJECT_CONTAINER_NAME}_npm" \
    --volume "$PROJECT_PATH:$PROJECT_PATH_IN_CONTAINER" \
    node:alpine \
    npm "$@"

    # $PROJECT_PATH is automatically being set.
    # $PROJECT_PATH_IN_CONTAINER is required for several global scripts but can
    # be omitted if you just use custom scripts.
  ```
Script names can contain alphanumeric and underscore characters and will be auto completed if a .sh file exists in .projet/scripts.

## Change to project
Execute `p cd [project_name]`. Project names are auto completed.

## Add, list, remove a project
- Execute `p add project_name /path/to/project` to add /register a project.
  Project names can container alphanumeric and underscore characters.
- `p remove project_name` removes the project from project-cmd.
  This does not deleting any project files.
- Show / list registered projects with their corresponding status if available: `p list`



## Bash completion / aliases
In order to use bash completion, add the following to your ~/.bash_aliases:

```
. /path/to/project-cmd/project-complete.bash
complete -F _project_autocomplete project
```

If you like being concise you can also add an alias for project


```
alias p='. /usr/bin/project'
complete -F _project_autocomplete p
```

## Show diff with file of another project
Since project-cmd tries to standardize the directory structured being used in
different projects, it turned out to be useful to see diffs of the same file in
another project.

For example to check the differences between current project's .env file and the
one of "my_other_project" you can run `p compare_with_project .env my_other_project`
to start a diff viewer. Depending on availability, meld, vimdiff, diff is being used.


## Example project structure

```
├── .project
│   ├── docker
│   │   ├── app
│   │   │   └── Dockerfile
│   │   └── db
│   │       └── Dockerfile
│   └── scripts
│       ├── build_theme.sh
│       ├── restart.sh
│       ├── start.sh
│       ├── status.sh
│       ├── stop.sh
│       └── vite.sh
├── src
│   ├── ...
│   └── ...
├── .env
└── docker-compose.dev.yml
```


## List of available commands

- project list: Shows all registered projects and their status if available.
- project cd project_name: Changes the current work dir to the project's location.
- project run script_name: Executes shell scripts. In this case it would execute the script in .project/scripts/script_name.sh
- project start: Executes the start script in .project/scripts/start.sh.
- project stop: Executes the stop script in .project/scripts/stop.sh.
- project status: Shows status information about the current project if it has one.