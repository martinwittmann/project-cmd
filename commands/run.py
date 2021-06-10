import click
from context import init_context
import subprocess
import util


@click.command(name='x', hidden=True)
@click.argument('script')
@click.pass_context
def run_script_alias(ctx, script):
    return ctx.invoke(run_script, script)


@click.command(name='run')
@click.argument('script')
@click.pass_context
def run_script(ctx, script):
    """(x) Execute a script defined in project.yml."""
    init_context(ctx)
    ctx.obj['config'].setup_project()
    if ctx.obj['verbosity'] > 0:
        util.debug('Running script {}'.format(script))
    command = ctx.obj['config'].get('scripts.{}'.format(script))
    subprocess.run(command.split(' '))
