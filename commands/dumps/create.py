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
    click.echo('Dumping database...')
    try:
        filename = ctx.obj['db'].dump(name)
        util.output_success('Database dumped to {}'.format(filename))
    except Exception:
        util.output_error('Error creating database dump.')


@click.command(name='dc', help=help_text, hidden=True)
@click.argument('name', default='%d')
@click.pass_context
def create_dump_alias(ctx, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(create_dump, name=name)
