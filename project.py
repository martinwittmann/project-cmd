import click
import context
import commands
import util

# Monkey patching click.ClickException to better format error messages.
click.ClickException.show = util.project_cmd_show_click_exception

VERSION = '0.4'


@click.group(invoke_without_command=True)
@click.option('--version', is_flag=True)
@click.pass_context
def main(ctx, version):
    context.init(ctx)
    if version:
        click.echo('Project cmd version {}'.format(VERSION))
        exit(0)

    if ctx.invoked_subcommand is None:
        ctx.invoke(commands.info)

main.add_command(commands.change_directory)
main.add_command(commands.change_directory_alias)

main.add_command(commands.info)
main.add_command(commands.info_alias)

main.add_command(commands.list_projects)
main.add_command(commands.list_project_alias)

main.add_command(commands.run_script)
main.add_command(commands.run_script_alias)


main.add_command(commands.status)
main.add_command(commands.status_alias)


@main.group(invoke_without_command=True)
@click.pass_context
def dumps(ctx):
    """(d) Lists the project's local database dumps."""
    # All dumps commands need a project to work on.
    context.init_project(ctx)

    if ctx.invoked_subcommand is None:
        ctx.invoke(commands.list_dumps)

dumps.add_command(commands.list_dumps)
main.add_command(commands.list_dumps_alias)

dumps.add_command(commands.create_dump)
main.add_command(commands.create_dump_alias)

dumps.add_command(commands.pull_dump)
main.add_command(commands.pull_dump_alias)

dumps.add_command(commands.push_dump)
main.add_command(commands.push_dump_alias)

dumps.add_command(commands.delete_local_dump)
main.add_command(commands.delete_local_dump_alias)

dumps.add_command(commands.delete_remote_dump)
main.add_command(commands.delete_remote_dump_alias)
