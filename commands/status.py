import click
from context import init_context
import util
import subprocess


@click.command(name='s', hidden=True)
@click.pass_context
def status_alias(ctx):
    ctx.invoke(status)


@click.command()
@click.pass_context
def status(ctx):
    """(s) Output the running state of the current project."""
    init_context(ctx)
    ctx.obj['config'].setup_project()
    if ctx.obj['verbosity'] > 0:
        util.debug('Running script status')
    # command = ctx.obj['config'].get('scripts.status')
    subprocess.run(['sudo', 'ls', '-la'])
