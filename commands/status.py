import click
import context
import util
import subprocess

help_text = '(s) Output the running state of the current project.'


@click.command(help=help_text)
@click.pass_context
def status(ctx):
    context.init_project(ctx)
    if ctx.obj['verbosity'] > 0:
        util.debug('Running script status')
    # command = ctx.obj['config'].get('scripts.status')
    subprocess.run(['sudo', 'ls', '-la'])


@click.command(name='s', help=help_text, hidden=True)
@click.pass_context
def status_alias(ctx):
    ctx.invoke(status)
