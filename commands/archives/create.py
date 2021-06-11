import click
import util

@click.option('-n', '--name', help='Name of the archive being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def create_archive(ctx, name):
    """(ac) Create tar.gz files of paths declared in 'archive' in project.yml."""

    click.echo('Creating archive...')
    try:
        filename = ctx.obj['archives'].create_archive(name)
        util.output_success('Created archive {}.'.format(filename))
    except Exception as e:
        util.output_error('Error creating archive: {}'.format(e))
