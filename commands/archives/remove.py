import click
import context
from completions import get_local_archives
import os
import util

help_text = """(ar) Delete local archive."""


@click.command(name='rm', help=help_text)
@click.argument('name', type=click.STRING, shell_complete=get_local_archives)
@click.pass_context
def delete_local_archive(ctx, name):
    try:
        filename = ctx.obj['archives'].get_filename(name)
        if filename is None or not os.path.isfile(filename):
            raise Exception('Can\'t delete archive "{}": File not found.'.format(name))
        basename = os.path.basename(filename)
        os.remove(filename)
        util.output_success('Deleted archive "{}".'.format(basename))
    except Exception as e:
        util.output_error(e)
