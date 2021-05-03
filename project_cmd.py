import click
import subprocess
from project_config import ProjectConfig
from database import Database

VERSION = '0.1'

@click.group(invoke_without_command=True)
@click.option('-v', '--verbose', is_flag=True,
              help='Show more output of what project-cmd is doing.')
@click.option('-vv', '--vverbose', is_flag=True,
              help='Show even more output of what project-cmd is doing.')
@click.option('--version', is_flag=True,
              help='Show version information.')
@click.pass_context
def main(context, verbose, vverbose, version):
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
    context.obj['db'] = Database(context.obj['config'])

    if version:
        click.echo('Project-Cmd version {}'.format(VERSION))
    elif not context.invoked_subcommand:
        click.echo(context.get_help())




@main.command()
@click.argument('script')
@click.pass_context
def run(context, script):
    """Execute a script defined in project.yml."""
    if context.obj['verbosity'] > 0:
        click.echo('Running script {}')
    command = context.obj['config'].get('scripts.{}'.format(script))
    subprocess.run(command.split(' '))


@main.group()
@click.pass_context
def db(context):
    """Create, import, push and download database dumps."""



@db.command()
@click.option('-n', '--name', help='Name the database dump that is being created. "%d" gets replace with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def dump(context, name):
    """Dumps the project's database."""
    click.echo('Dumping database...')
    filename = context.obj['db'].dump(name)
    click.echo('Created local database dump at {}'.format(filename))
