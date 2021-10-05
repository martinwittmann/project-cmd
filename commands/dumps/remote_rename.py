import click
import context
import util

from completions import get_remote_dumps

help_text = """(drrn) Rename remote database dump.

You can use '%d' in NAME which gets replace with YYYY-MM-DD--HH:MM:SS which
is also the default name.
"""


@click.command(name='rrename', help=help_text)
@click.argument('dump', type=click.STRING, autocompletion=get_remote_dumps)
@click.argument('name', type=click.STRING)
@click.pass_context
def rename_remote_dump(ctx, dump, name):
    try:
        project_id = ctx.obj['config'].get('id')
        old_filename = ctx.obj['ssh'].get_remote_filename(project_id, 'dumps', dump, True)
        new_filename = ctx.obj['ssh'].get_remote_filename(project_id, 'dumps', name)
        ctx.obj['ssh'].rename_remote_file(old_filename, new_filename)
        util.output_success('Renamed remote database dump "{}" to "{}".'
                            .format(dump, name))
    except Exception as e:
        util.output_error('Error renaming remote database dump: {}'.format(e))
