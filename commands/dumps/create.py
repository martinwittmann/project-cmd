import click
import util
import context

help_text = """(dc) Dumps the project's database to NAME[.dump_file_extension].

You can use '%d' in NAME which gets replace with YYYY-MM-DD--HH:MM:SS which
is also the default name.
"""


@click.command(name='create', help=help_text)
@click.argument('name', default='%d')
@click.pass_context
def create_dump(ctx, name):
    try:
        click.echo('Dumping database...')
        filename = ctx.obj['db'].dump(name)
        util.output_success('Database dumped to {}'.format(filename))
    except Exception as e:
        util.output_error(e)
