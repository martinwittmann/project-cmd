import click
from completions import get_local_archives
import context
import util

help_text = """(ax) Extract an archive, possibly overwriting local files."""


@click.command(name='extract', help=help_text)
@click.argument('name', type=click.STRING, autocompletion=get_local_archives)
@click.pass_context
def extract_archive(ctx, name):
    click.echo('Extracting archive...')
    try:
        filename = ctx.obj['archives'].extract_archive(name)
        util.output_success('Extracted archive {}.'.format(filename))
    except Exception as e:
        util.output_error(e)


@click.command(name='ax', help=help_text, hidden=True)
@click.argument('name', type=click.STRING, autocompletion=get_local_archives)
@click.pass_context
def extract_archive_alias(ctx, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(extract_archive, name=name)
