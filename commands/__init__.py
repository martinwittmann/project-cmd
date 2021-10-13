import click
import context

from . import global_commands

from .archives.list import list_archives
from .archives.create import create_archive
from .archives.extract import extract_archive
from .archives.push import push_archive
from .archives.pull import pull_archive
from .archives.remove import delete_local_archive
from .archives.remote_remove import delete_remote_archive
from .archives.rename import rename_local_archive
from .archives.remote_rename import rename_remote_archive

from .dumps.create import create_dump
from .dumps.list import list_dumps
from .dumps.pull import pull_dump
from .dumps.push import push_dump
from .dumps.remote_remove import delete_remote_dump
from .dumps.remote_rename import rename_remote_dump
from .dumps.remove import delete_local_dump
from .dumps.rename import rename_local_dump

from .hosts import add
from .hosts import list
from .hosts import remove


# Even when using invoke_without_command, this function des not get called when
# using CommandCollection as we do.
@click.group()
@click.pass_context
def commands(ctx):
    pass

# Add global commands to group directly.
commands.add_command(global_commands.cd_to_project)
commands.add_command(global_commands.show_project_info)
commands.add_command(global_commands.list_projects)
commands.add_command(global_commands.run_command)
commands.add_command(global_commands.start_project)
commands.add_command(global_commands.status)

@commands.group(invoke_without_command=True)
@click.pass_context
def archives(ctx):
    """(a) Manage archives for the current project."""
    # All archives commands need a project to work on.
    context.init_project(ctx)

    if ctx.invoked_subcommand is None:
        ctx.invoke(list_archives)


archives.add_command(list_archives)
archives.add_command(create_archive)
archives.add_command(extract_archive)
archives.add_command(delete_local_archive)
archives.add_command(push_archive)
archives.add_command(pull_archive)
archives.add_command(delete_remote_archive)
archives.add_command(rename_local_archive)
archives.add_command(rename_remote_archive)


@commands.group(invoke_without_command=True)
@click.pass_context
def dumps(ctx):
    """(d) Lists the project's local database dumps."""
    # All dumps commands need a project to work on.
    context.init_project(ctx)

    if ctx.invoked_subcommand is None:
        ctx.invoke(list_dumps)


dumps.add_command(list_dumps)
dumps.add_command(create_dump)
dumps.add_command(pull_dump)
dumps.add_command(push_dump)
dumps.add_command(delete_local_dump)
dumps.add_command(delete_remote_dump)
dumps.add_command(rename_local_dump)
dumps.add_command(rename_remote_dump)
