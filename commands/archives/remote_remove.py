import click
import context
from completions import get_remote_archives
import os
import util

help_text = """(arr) Delete remote archive from server."""


@click.command(name='rrm', help=help_text)
@click.argument('name', type=click.STRING, autocompletion=get_remote_archives)
@click.pass_context
def delete_remote_archive(ctx, name):
    try:
        project_id = ctx.obj['config'].get('id')
        ctx.obj['ssh'].connect()
        remote_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'archives')
        remote_filename = os.path.join(remote_dir, name)

        if not ctx.obj['ssh'].remote_file_exists(remote_filename):
            raise Exception('Can\'t delete remote archive {}: File not found.'.format(name))

        ctx.obj['ssh'].delete_remote_file(remote_filename)
        util.output_success('Deleted remote archive "{}".'.format(name))
    except Exception as e:
        util.output_error(e)


@click.command(name='arr', help=help_text, hidden=True)
@click.argument('name', type=click.STRING, autocompletion=get_remote_archives)
@click.pass_context
def delete_remote_archive_alias(ctx, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(delete_remote_archive, name=name)

