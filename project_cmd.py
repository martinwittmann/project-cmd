import click
import project_config

@click.group()
def main():
    """A standardized way to manage project files and database dumps."""


@click.command()
def run():
    """Execute a script defined in .project."""
