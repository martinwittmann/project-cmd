import click
import context
import util

from completions import get_local_archives

help_text = """(arn) Rename local archive.

You can use '%d' in NAME which gets replace with YYYY-MM-DD--HH:MM:SS which
is also the default name.
"""


@click.command(name='rename', help=help_text)
@click.argument('archive', type=click.STRING, shell_complete=get_local_archives)
@click.argument('name', type=click.STRING)
@click.pass_context
def rename_local_archive(ctx, archive, name):
    try:
        project_id = ctx.obj['config'].get('id')
        old_filename = ctx.obj['ssh'].get_local_filename(
            project_id=project_id,
            type='archives',
            name=archive,
            check_existing=True,
        )
        new_filename = ctx.obj['ssh'].get_local_filename(
            project_id=project_id,
            type='archives',
            name=name,
        )
        ctx.obj['ssh'].rename_local_file(old_filename, new_filename)
        util.output_success('Renamed local archive "{}" to "{}".'
                            .format(archive, name))
    except Exception as e:
        util.output_error('Error renaming local archive: {}'.format(e))
