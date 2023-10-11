import click
import context
from completions import get_local_dumps
import os
import util

help_text = """(dr) Delete local database dump."""


@click.command(name='rm', help=help_text)
@click.argument('name', type=click.STRING, shell_complete=get_local_dumps)
@click.pass_context
def delete_local_dump(ctx, name):
    try:
        filename = ctx.obj['db'].get_dump_filename(name)
        if filename is None or not os.path.isfile(filename):
            raise Exception('Can\'t delete database dump "{}": File not found.'.format(name))
        basename = os.path.basename(filename)
        os.remove(filename)
        util.output_success('Deleted database dump "{}".'.format(basename))
    except Exception as e:
        util.output_error(e)
