import click
import context
from completions import project_names
import util

help_text = '(c) Change directory to the given project.'


@click.command(name='cd', help=help_text)
@click.pass_context
@click.argument('name', autocompletion=project_names)
def change_directory(ctx, name):
    try:
        context.init(ctx)
        projects = ctx.obj['config'].get_all_projects()
        for project in projects:
            if project['id'] == name:
                click.echo('cd ' + project['location'])
                return

        raise Exception('Project "{}" could not be found.'.format(name))
    except Exception as e:
        util.output_error(e)


@click.command(name='c', help=help_text, hidden=True)
@click.pass_context
@click.argument('name', autocompletion=project_names)
def change_directory_alias(ctx, name):
    return ctx.invoke(change_directory, name=name)
