import click
import context
import subprocess
import util

help_text = '(s) Start the current project.'


@click.command(name='start', help=help_text)
@click.pass_context
def start_project(ctx):
    try:
        context.init_project(ctx)
        click.secho('Starting {}...'.format(ctx.obj['config'].get('name')))
        ctx.obj['docker'].get_dependencies()
    except Exception as e:
        util.output_error(e)



@click.command(name='s', help=help_text, hidden=True)
@click.pass_context
def start_project_alias(ctx):
    return ctx.invoke(start_project)
