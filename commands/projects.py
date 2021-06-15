import click
from constants import colors

help_text = '(p) List all registered projects symlinked from ~/.project/projects.'


@click.command(name='projects', help=help_text)
@click.pass_context
@click.option('-I', '--only-ids', is_flag=True, help='Output a space separated list of project ids.')
def list_projects(ctx, only_ids):
    projects = ctx.obj['config'].get_all_projects()

    if only_ids:
        ids = list(map(lambda p: p['id'], projects))
        click.echo(' '.join(ids))
    else:
        table = list(map(lambda p: [p['id'], p['location']], projects))
        click.echo('Found {} projects:'.format(len(table)))
        ctx.obj['simple_table'].print(table, border_styles={
            'fg': colors.borders
        }, headers=[
            'Project id',
            'Path',
        ])


@click.command(name='p', help=help_text, hidden=True)
@click.pass_context
@click.option('-I', '--only-ids', is_flag=True, help='Output a space separated list of project ids.')
def list_project_alias(ctx, only_ids):
    ctx.invoke(list_projects, only_ids=only_ids)
