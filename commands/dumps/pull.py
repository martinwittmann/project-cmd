import click

import context
from completions import get_remote_dumps
import os
import util

help_text = """(dd) Pull/download database dump from server."""


@click.command(name='pull', help=help_text)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=get_remote_dumps)
@click.pass_context
def pull_dump(ctx, dump, verbose):
    try:
        project_id = ctx.obj['config'].get('id')
        remote_filename = ctx.obj['ssh'].get_remote_filename(
            project_id,
            'dumps',
            dump,
            True
        )
        local_filename = ctx.obj['ssh'].get_local_filename(
            project_id,
            'dumps',
            dump
        )
        click.echo(local_filename)
        ctx.obj['ssh'].download_file(remote_filename, local_filename)
        basename = os.path.basename(remote_filename)
        util.output_success('Downloaded local database dump {} from server.'
                            .format(basename))
    except Exception as e:
        util.output_error('Remote database dump not found in project {}: {}'.format(ctx.obj['config'].get('id'), dump))
