import click
import util
from completions import get_local_archives
from constants import colors
import context


help_text = """(a) Lists the project's archives."""


@click.command(name='list', help=help_text)
@click.argument('pattern', default='*', type=click.STRING,
                autocompletion=get_local_archives)
@click.pass_context
def list_archives(ctx, pattern):
    try:
        project_name = ctx.obj['config'].get('name')
        project_id = ctx.obj['config'].get('id')
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

        click.echo()
        click.echo('Remote archives:')

        remote_archives = ctx.obj['ssh'].get_archives(project_id, include_details=True)
        if len(remote_archives) < 1:
            click.secho('  [No remote archives found]', fg=colors.highlight)
        else:
            table = list(map(lambda d: [d['name'], d['date'], d['size']], remote_archives))
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
    except Exception as e:
        util.output_error(e)


@click.command(name='a', help=help_text, hidden=True)
@click.argument('pattern', default='*', type=click.STRING,
                autocompletion=get_local_archives)
@click.pass_context
def list_archives_alias(ctx, pattern):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(list_archives, pattern=pattern)
