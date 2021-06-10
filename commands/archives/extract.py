import click
from completions import get_local_archives
import util


@click.argument('name', type=click.STRING, autocompletion=get_local_archives)
@click.pass_context
def extract_archive(ctx, name):
    """(ax) Extract an archive, possibly overwriting local files."""
    click.echo('Extracting archive...')
    ctx.obj['config'].setup_project()
    try:
        filename = ctx.obj['archives'].extract_archive(name)
        util.output_success('Extracted archive {}.'.format(filename))
    except Exception as e:
        util.output_error(e)


