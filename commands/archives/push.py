import click
import context
from completions import get_local_archives
import os
import util

help_text = """(du) Push/upload archive to server."""


@click.command('push', help=help_text)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('archive', type=click.STRING, autocompletion=get_local_archives)
@click.pass_context
def push_archive(ctx, archive, verbose):
    try:
        project_id = ctx.obj['config'].get('id')
        local_archive_filename = ctx.obj['archives'].get_filename(archive)
        if local_archive_filename is None:
            util.output_error('Archive not found in project {}: {}'.format(ctx.obj['config'].get('id'), archive))
        ctx.obj['ssh'].connect()

        basename = os.path.basename(local_archive_filename)
        remote_archives_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'archives')
        remote_filename = os.path.join(remote_archives_dir, basename)
        ctx.obj['ssh'].upload_file(local_archive_filename, remote_filename)

        util.output_success('Uploaded local archive {} to server.'.format(basename))
    except Exception as e:
        util.output_error(e)


@click.command(name='au', help=help_text, hidden=True)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('archive', type=click.STRING, autocompletion=get_local_archives)
@click.pass_context
def push_archive_alias(ctx, archive, verbose):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(push_archive, archive=archive, verbose=verbose)
