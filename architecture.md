# Architecture

Project-cmd's goal was to create a light script to standardize the way developers can work with projects.
By working with projects we mean defining environment data, starting, stopping them and their dependencies,
switching between them and using the required tooling - everything in containers via docker composer where
required. But any other containerization technology can be used just as easily.

Since one way to look at it is to run scripts/commands for a project this also creates the use-case for
deploying projects on servers if the hosting setup is simple. In this case users can install project-cmd
on the server and use it to start, stop, backup,... the projects just like when developing.

# Questions / issues

This project has grown quite a bit for a collection of bash scripts and the limitations and development
complexities are an issue already.

Also bash scripting is not directly available under windows will create setup difficulties for those users.

So the question is whether rewriting most of it to use something like python click - which has very broad
platform support and offers all advantages of a full programming language.

This would make working on project-cmd a lot easier and for templating python 3 is already required anyway.

What keeps us from switching are 2 issues:
- Parts of the code need to be bash since 'project cd' is an incredibly useful command.
- Using python would probably mean that all project scripts need to be written in python too

This would turn every created project into a python project or would require bash wrappers for
every function project-cmd provides.

Additionally it would be unclear how to handle environment variables for project.

The beauty of the current approach is that .env files are usable a generic/bash .env files
and are just being sourced so their variables are available als globals in all project-cmd
and custom scripts.

Developers known what that is and how this works.

## So what to do?