# Project-cmd: Command line utilities for managing software projects.
Project cmd enables a standardized and mostly technology-agnostic way of handling software projects:

List registered projects with their name, location and status.
Start, stop and run any scripts like building in any sub directory of the project.
Cd into any project directory with "project cd [project-name]". Or even easier with an alias (p cd [project-name]).
Set up + configure your project via a .env file.
If you use docker you can retrieve the project's status.
Define custom commands using shell scripts by running "project run [command]" or "project x [command]". Of course you can use npm/npx/yarn/...
Autocomplete for project names, commands,...


# Who can profit by using Project Cmd
Project cmd standardizes the day-to-day work of software developers working on
multiple projects possibly with different technologies. It also helps to quickly set up development environments.


# Usage

## Setup + register projects

Add project-cmd to your $PATH either via .bashrc or by adding a link to /usr/bin as
superuser or via sudo:

```
cd /usr/bin
ln -s /path/to/project-cmd project
```

Create the directory ~/.projects. To register a project create a symbolic link to the corresponding directory:

```
cd ~/.projects
ln -s /path/to/project project_name
```

To keep things easy and standardized please only use alphanumeric characters and
underscores for project names.


## Bash completion / aliases

In order to use bash completion, add the following to your ~/.bash_aliases:

```
source /path/to/project-cmd/project-complete.bash
complete -F _project_autocomplete project
```

If you like being concise you can also add an alias for project


```
alias p='source /usr/bin/project'
complete -F _project_autocomplete p
```


## Settings things up in project directories
Project-cmd expects 2 things in project directories:

- a .env file in the project's root directory. This can be empty if you want.
- a .project directory

Optionally you can create .project/scripts and add custom shell scripts. For example

```
project cd my_project
cd .project/scripts
touch build.sh
# Add script commands to build.sh
project run build

# Note that you can run scripts from any (sub)directory inside the project path. E.g.:
project cd my_project
cd src/lib/foo
project run build # This still works.
```


## Starting + stopping projects (if applicable)

Project-cmd has 2 special commands: start, stop that simply execute the project scripts .project/scripts/start.sh and .project/scripts/stop.sh if existing.


## Available project commands


- project list: Shows all registered projects and their status if available.
- project cd project_name: Changes the current work dir to the project's location.
- project run script_name: Executes shell scripts. In this case it would execute the script in .project/scripts/script_name.sh
- project start: Executes the start script in .project/scripts/start.sh.
- project stop: Executes the stop script in .project/scripts/stop.sh.
- project status: Shows status information about the current project if it has one.


## Custom scripts

You can create custom scripts by creating a .sh file in .project/scripts. For Example ".project/scripts/tests.sh":

```
#!/bin/bash

# Create a shell function with the name _project_[PROJECT_NAME]_run_[SCRIPT_NAME]:
_project_project_name_run_tests() {
	# TODO Add script logic.
}

# Optionally you can create a second function for shell completion for available
# arguments your script expects:

_project_project_name_complete_tests() {
  local options=("all" "frontend" "backend")
  COMPREPLY=($(compgen -W "${options[*]}" -- $cur))
}
```