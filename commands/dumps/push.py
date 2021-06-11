import click
import context
from completions import get_local_dumps
import os
import util

@click.command('push')
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=get_local_dumps)
@click.pass_context
def push_dump(ctx, dump, verbose):
    """(du) Push/upload database dump to server."""

    project_id = ctx.obj['config'].get('id')
    local_dump = ctx.obj['db'].get_dump_filename(dump)
    if local_dump is None:
        util.output_error('Database dump not found in project {}: {}'.format(ctx.obj['config'].get('id'), dump))
    ctx.obj['ssh'].connect()

    basename = os.path.basename(local_dump)
    remote_dumps_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'dumps')
    remote_filename = os.path.join(remote_dumps_dir, basename)
    ctx.obj['ssh'].put_file(local_dump, remote_filename)

    util.output_success('Uploaded local database dump {} to server.'.format(basename))


@click.command(name='du', hidden=True)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=get_local_dumps)
@click.pass_context
def push_dump_alias(ctx, dump, verbose):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(push_dump, dump=dump, verbose=verbose)
