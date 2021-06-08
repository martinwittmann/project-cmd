# Project Cmd (pre-alpha)

Command line utilities for managing software projects.<br>
Project cmd enables a standardized and mostly unopinionated way of handling software projects:

* Starting, stopping, building, running development servers.
* Defining dependencies between multiple projects (think reverse proxy, database servers,...) and starting the needed stack.
* Creating and importing database dumps.
* Uploading + downloading dumps to and from a server via ssh.
* Declaring files + directories that can be gzipped to create restorable states. Useful for all data files and content that are not database dumps.
* Uploading + downloading these gzipped files to and from a server via ssh.
* Cd into any project directory with "project cd [project-name]". Or even easier with an alias (p cd [project-name]).
* Set up + configure your project via a project.yml file. Similar to package.json but technology independent.
* Define custom commands using shell scripts by running "project run [command]" or "project x [command]". Of course you can use npm/npx/yarn/...
* Autocomplete everything: Project names, database dumps, commands,...
* Project templates: Quickly create reproducable projects based on definable templates.
* Manage hosts files: List, add and remove host entries via single commands.


# Who can profit by using Project Cmd

Project cmd standardizes the day-to-day work of software developers working on
multiple projects with different technologies. It also helps to quickly set up
development environments (when depending on docker) and enables developers to
quickly switch between computers by being able to create, upload, download and
restore states of your projects.