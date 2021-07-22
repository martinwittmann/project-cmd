import click
import context
import util

help_text = """(ac) Create tar.gz archive of paths declared in 'archive' in project.yml.

You can use '%d' in NAME which gets replace with YYYY-MM-DD--HH:MM:SS which
is also the default name.
"""


@click.command(name='create', help=help_text)
@click.argument('name', default='%d')
@click.pass_context
def create_archive(ctx, name):
    try:
        click.echo('Creating archive...')
        filename = ctx.obj['archives'].create_archive(name)
        util.output_success('Created archive {}.'.format(filename))
    except Exception as e:
        util.output_error('Error creating archive: {}'.format(e))


@click.command('ac', help=help_text, hidden=True)
@click.argument('name', default='%d')
@click.pass_context
def create_archive_alias(ctx, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(create_archive, name=name)
