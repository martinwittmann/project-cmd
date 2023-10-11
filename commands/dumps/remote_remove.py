import click
import context
from completions import get_remote_dumps
import os
import util

help_text = """(drr) Delete remote database dump from server."""


@click.command(name='rrm', help=help_text)
@click.argument('name', type=click.STRING, shell_complete=get_remote_dumps)
@click.pass_context
def delete_remote_dump(ctx, name):
    try:
        project_id = ctx.obj['config'].get('id')
        ctx.obj['ssh'].connect()
        remote_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'dumps')
        remote_filename = os.path.join(remote_dir, name)

        if not ctx.obj['ssh'].remote_file_exists(remote_filename):
            raise Exception('Can\'t delete remote database dump {}: File not found.'.format(name))

        ctx.obj['ssh'].delete_remote_file(remote_filename)
        util.output_success('Deleted remote database dump "{}".'.format(name))
    except Exception as e:
        util.output_error(e)
