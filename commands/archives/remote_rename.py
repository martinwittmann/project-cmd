import click
import context
import util

from completions import get_remote_archives

help_text = """(drrn) Rename remote database archive.

You can use '%d' in NAME which gets replace with YYYY-MM-DD--HH:MM:SS which
is also the default name.
"""


@click.command(name='rrename', help=help_text)
@click.argument('archive', type=click.STRING, autocompletion=get_remote_archives)
@click.argument('name', type=click.STRING)
@click.pass_context
def rename_remote_archive(ctx, archive, name):
    try:
        project_id = ctx.obj['config'].get('id')
        old_filename = ctx.obj['ssh'].get_remote_filename(project_id, 'archives', archive, True)
        new_filename = ctx.obj['ssh'].get_remote_filename(project_id, 'archives', name)
        ctx.obj['ssh'].rename_remote_file(old_filename, new_filename)
        util.output_success('Renamed remote archive "{}" to "{}".'
                            .format(archive, name))
    except Exception as e:
        util.output_error('Error renaming remote archive: {}'.format(e))
