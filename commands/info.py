import click
from context import init_context
from constants import colors

@click.command(name='i', hidden=True)
@click.pass_context
def info_alias(ctx):
    return ctx.invoke(info)

@click.command()
@click.pass_context
def info(ctx):
    """(i) Show information about the current project."""
    init_context(ctx)
    ctx.obj['config'].setup_project()
    click.echo('Found project at {}:'.format(ctx.obj['config'].project_dir))
    data = [
        [
            'Project',
            ctx.obj['config'].get('name'),
        ],
        [
            'Id',
            ctx.obj['config'].get('id'),
        ],
    ]

    if ctx.obj['config'].has_key('domain'):
        data.append([
            'Domain',
            ctx.obj['config'].get('domain'),
        ])
    ctx.obj['simple_table'].print(data, border_styles={
        'fg': colors.borders
    })
