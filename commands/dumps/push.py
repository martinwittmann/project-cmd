import click
import context
from completions import get_local_dumps
import os
import util

help_text = """(du) Push/upload database dump to server."""


@click.command('push', help=help_text)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, shell_complete=get_local_dumps)
@click.pass_context
def push_dump(ctx, dump, verbose):
    try:
        project_id = ctx.obj['config'].get('id')
        local_dump = ctx.obj['db'].get_dump_filename(dump)
        if local_dump is None:
            util.output_error('Database dump not found in project {}: {}'.format(ctx.obj['config'].get('id'), dump))
        ctx.obj['ssh'].connect()

        basename = os.path.basename(local_dump)
        remote_dumps_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'dumps')
        remote_filename = os.path.join(remote_dumps_dir, basename)
        ctx.obj['ssh'].upload_file(local_dump, remote_filename)

        util.output_success('Uploaded local database dump {} to server.'.format(basename))
    except Exception as e:
        util.output_error(e)
