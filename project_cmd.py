import click
import subprocess
from project_config import ProjectConfig

@click.group()
@click.option('-v', '--verbose', is_flag=True,
              help='Show more output of what project-cmd is doing.')
@click.option('-V', '--vverbose', is_flag=True,
              help='Show even more output of what project-cmd is doing.')
@click.pass_context
def main(context, verbose, vverbose):
    """A standardized way to manage project files and database dumps."""
    if context.obj is None:
        context.obj = dict()
    context.obj['verbosity'] = 0
    if verbose:
        context.obj['verbosity'] = 1
    if vverbose:
        context.obj['verbosity'] = 2
    context.obj['config'] = ProjectConfig(context.obj['verbosity'])
    context.obj['project_dir'] = context.obj['config'].project_dir

@main.command()
@click.argument('script')
@click.pass_context
def run(context, script):
    """Execute a script defined in .project."""
    if context.obj['verbosity'] > 0:
        click.echo('Running script {}')
    command = context.obj['config'].get('scripts.{}'.format(script))
    subprocess.run(command.split(' '))

