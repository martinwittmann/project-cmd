import click

import context
from completions import get_remote_dumps
import os
import util

@click.command(name='pull')
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=get_remote_dumps)
@click.pass_context
def pull_dump(ctx, dump, verbose):
    """(dd) Pull/download database dump from server."""

    project_id = ctx.obj['config'].get('id')
    local_dump = ctx.obj['db'].get_dump_filename(dump)
    if local_dump is None:
        util.output_error('Database dump not found in project {}: {}'.format(ctx.obj['config'].get('id'), dump))
    ctx.obj['ssh'].connect()

    basename = os.path.basename(local_dump)
    remote_dumps_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'dumps')
    remote_filename = os.path.join(remote_dumps_dir, basename)
    ctx.obj['ssh'].get_file(remote_filename, local_dump)
    util.output_success('Downloaded local database dump {} from server.'.format(basename))

@click.command(name='dd', hidden=True)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=get_remote_dumps)
@click.pass_context
def pull_dump_alias(ctx, dump, verbose):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(pull_dump, dump=dump, verbose=verbose)
