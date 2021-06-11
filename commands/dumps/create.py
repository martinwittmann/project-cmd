import click
import util
import context

@click.command(name='create')
@click.option('-n', '--name', help='Name of the database dump being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def create_dump(ctx, name):
    """(dc) Dumps the project's database."""

    click.echo('Dumping database...')
    try:
        filename = ctx.obj['db'].dump(name)
        util.output_success('Database dumped to {}'.format(filename))
    except Exception:
        util.output_error('Error creating database dump.')


@click.command(name='dc', hidden=True)
@click.argument('name', default='%d')
@click.pass_context
def create_dump_alias(ctx, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(create_dump, name=name)
