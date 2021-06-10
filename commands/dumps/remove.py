import click
from completions import get_local_dumps
import os
import util

@click.argument('name', type=click.STRING, autocompletion=get_local_dumps)
@click.pass_context
def dumps_rm_local(ctx, name):
    """(dr) Delete local database dump."""
    try:
        filename = ctx.obj['db'].get_dump_filename(name)
        if filename is None or not os.path.isfile(filename):
            raise Exception('Can\'t delete database dump "{}": File not found.'.format(name))
        basename = os.path.basename(filename)
        os.remove(filename)
        util.output_success('Deleted database dump "{}".'.format(basename))
    except Exception as e:
        util.output_error(e)

