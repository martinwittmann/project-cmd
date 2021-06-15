import click

import context
from completions import get_remote_archives
import os
import util

@click.command(name='pull')
@click.option('-v', '--verbose', is_flag=True)
@click.argument('archive', type=click.STRING, autocompletion=get_remote_archives)
@click.pass_context
def pull_archive(ctx, archive, verbose):
    """(ad) Pull/download archive from server."""

    try:
        project_id = ctx.obj['config'].get('id')
        ctx.obj['ssh'].connect()

        remote_filename = ctx.obj['ssh'].get_remote_filename(
            project_id,
            'archives',
            archive,
            True
        )
        local_filename = ctx.obj['ssh'].get_local_filename(
            project_id,
            'archives',
            archive
        )
        basename = os.path.basename(remote_filename)
        ctx.obj['ssh'].download_file(remote_filename, local_filename)
        util.output_success('Downloaded local database dump {} from server.'.format(basename))
    except Exception as e:
        util.output_error(e)

@click.command(name='dd', hidden=True)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=get_remote_archives)
@click.pass_context
def pull_dump_alias(ctx, dump, verbose):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(pull_dump, dump=dump, verbose=verbose)
