import click
from completions import get_local_archives
from constants import colors


@click.argument('pattern', default='*', type=click.STRING,
                autocompletion=get_local_archives)
@click.pass_context
def list_archives(ctx, pattern):
    """(a) Lists the project's archives."""
    project_name = ctx.obj['config'].get('name')
    click.secho('[{}]'.format(project_name), fg=colors.success, bold=True)
    click.echo()
    click.echo('Local archives:')
    local_archives = ctx.obj['archives'].get_local_archives(pattern, include_details=True)
    if len(local_archives) < 1:
        click.secho('  [No archives found]', fg=colors.highlight)

    else:
        table = list(map(lambda d: [d['name'], d['date'], d['size']], local_archives))
        ctx.obj['simple_table'].print(
            table,
            border_styles={
                'fg': colors.borders
            },
            column_settings=[
                {},
                {
                    'align': 'center',
                },
                {
                    'align': 'right',
                },
            ],
            headers=[
                'Name',
                'Date',
                'Size',
            ],
            width='full',
            show_horizontal_lines=False,
        )
