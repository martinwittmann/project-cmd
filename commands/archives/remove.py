import click
import context
from completions import get_local_archives
import os
import util

@click.command(name='rm')
@click.argument('name', type=click.STRING, autocompletion=get_local_archives)
@click.pass_context
def delete_local_archive(ctx, name):
    """(ar) Delete local archive."""

    try:
        filename = ctx.obj['archives'].get_filename(name)
        if filename is None or not os.path.isfile(filename):
            raise Exception('Can\'t delete archive "{}": File not found.'.format(name))
        basename = os.path.basename(filename)
        os.remove(filename)
        util.output_success('Deleted archive "{}".'.format(basename))
    except Exception as e:
        util.output_error(e)

@click.command(name='ar', hidden=True)
@click.argument('name', type=click.STRING, autocompletion=get_local_archives)
@click.pass_context
def delete_local_archive_alias(ctx, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(delete_local_archive, name=name)
