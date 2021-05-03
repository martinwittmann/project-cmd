import click
from project_config import ProjectConfig

@click.group()
@click.option('-v', '--verbose', is_flag=True,
              help='Show more output of what project-cmd is doing.')
@click.option('-V', '--vverbose', is_flag=True,
              help='Show even more output of what project-cmd is doing.')
@click.pass_context
def main(context, verbose, vverbose):
    """A standardized way to manage project files and database dumps."""
    context.verbosity = 0
    if verbose:
        context.verbosity = 1
    if vverbose:
        context.verbosity = 2
    context._config = ProjectConfig(context.verbosity)
    context.config = context._config.get_config_location()


@main.command()
@click.pass_context
def run(context):
    """Execute a script defined in .project."""
    click.echo('Running...')
