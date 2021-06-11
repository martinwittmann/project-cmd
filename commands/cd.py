import click

import context
from completions import project_names
import util


@click.command(name='c', hidden=True)
@click.pass_context
@click.argument('name', autocompletion=project_names)
def change_directory_alias(ctx, name):
    return ctx.invoke(change_directory, name=name)


@click.command(name='cd')
@click.pass_context
@click.argument('name', autocompletion=project_names)
def change_directory(ctx, name):
    """(c) Change directory to the given project."""

    context.init(ctx)
    projects = ctx.obj['config'].get_all_projects()
    for project in projects:
        if project['id'] == name:
            click.echo('cd ' + project['location'])
            return

    util.output_error('Project "' + name + '" could not be found.')
