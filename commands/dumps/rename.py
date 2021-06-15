import click
import context
import util

from completions import get_local_dumps

help_text = """(drn) Rename local database dump.

You can use '%d' in NAME which gets replace with YYYY-MM-DD--HH:MM:SS which
is also the default name.
"""


@click.command(name='rename', help=help_text)
@click.argument('dump', type=click.STRING, autocompletion=get_local_dumps)
@click.argument('name', type=click.STRING)
@click.pass_context
def rename_local_dump(ctx, dump, name):
    try:
        old_filename = ctx.obj['db'].get_dump_filename(dump)
        new_filename = ctx.obj['db'].get_dump_filename(name)
        ctx.obj['ssh'].rename_local_file(old_filename, new_filename)
        util.output_success('Renamed database dump "{}" to "{}".'
                            .format(dump, name))
    except Exception as e:
        util.output_error('Error renaming database dump: {}'.format(e))


@click.command(name='drn', help=help_text, hidden=True)
@click.argument('dump', type=click.STRING, autocompletion=get_local_dumps)
@click.argument('name', type=click.STRING)
@click.pass_context
def rename_local_dump_alias(ctx, dump, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(rename_local_dump, dump=dump, name=name)
