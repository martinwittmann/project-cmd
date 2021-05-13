import sys

import click
import subprocess
from project_config import ProjectConfig
from database import Database
from project_util import project_cmd_show_click_exception, debug

# Monkey patching click.ClickException to better format error messages.
click.ClickException.show = project_cmd_show_click_exception

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
@click.pass_context
def status(context):
    """Checking the running state of the current project."""
    if context.obj['verbosity'] > 0:
        debug('Running script status')
    command = context.obj['config'].get('scripts.status')
    subprocess.run(command.split(' '))


@main.command()
@click.argument('script')
@click.pass_context
def run(context, script):
    """Execute a script defined in project.yml."""
    if context.obj['verbosity'] > 0:
        debug('Running script {}'.format(script))
    command = context.obj['config'].get('scripts.{}'.format(script))
    subprocess.run(command.split(' '))


@main.group()
@click.pass_context
def dumps(ctx):
    """Create, import, push and download database dumps for the current project."""



@dumps.command()
@click.option('-n', '--name', help='Name of the database dump being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def dump(ctx, name):
    """Dumps the project's database."""
    click.echo('Dumping database...')
    filename = ctx.obj['db'].dump(name)
    click.echo('Created local database dump at {}'.format(filename))

def _get_dumps(ctx, args, incomplete):
    #dumps = ctx.obj['db'].get_local_dumps(incomplete)
    print(ctx.obj['db'])
    return ['sdfasd', '123']

@dumps.command()
@click.argument('dump', default='*', type=click.STRING, autocompletion=_get_dumps)
@click.pass_context
def ls(context, pattern):
    """Lists the project's local database dumps."""
    project_name = context.obj['config'].get('name')
    click.secho('[{}]'.format(project_name), fg='green', nl=False)
    click.echo(' Local database dumps:'.format(click.format_filename(project_name)))
    dumps = context.obj['db'].get_local_dumps(pattern)
    for dump in dumps:
        click.echo('  {}'.format(dump))
