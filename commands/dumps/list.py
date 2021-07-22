import click
import context
import util
from completions import get_local_dumps
from constants import colors

help_text = """(d) Lists the project's local database dumps."""


@click.command(name='list', help=help_text)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('pattern', default='*', type=click.STRING, autocompletion=get_local_dumps)
@click.pass_context
def list_dumps(ctx, pattern, verbose):
    try:
        project_id = ctx.obj['config'].get('id')
        project_name = ctx.obj['config'].get('name')
        click.secho('[{}]'.format(project_name), fg=colors.success, bold=True)
        click.echo()
        click.echo('Local database dumps:')
        local_dumps = ctx.obj['db'].get_local_dumps(pattern, include_details=True)
        if len(local_dumps) < 1:
            click.secho('  [No database dumps found]', fg=colors.highlight)

        else:
            table = list(map(lambda d: [d['name'], d['date'], d['size']], local_dumps))
            ctx.obj['simple_table'].print(
                table,
                border_styles={
                    'fg': colors.borders,
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

        click.echo('')
        click.echo('Remote database dumps:')
        if verbose:
            ctx.obj['ssh'].set_verbosity(1)
        ctx.obj['ssh'].connect()
        remote_dumps = ctx.obj['ssh'].get_dumps(project_id, include_details=True)
        if len(remote_dumps) < 1:
            click.secho('[No database dumps found]', fg=colors.highlight)
        else:
            table = list(map(lambda d: [d['name'], d['date'], d['size']], remote_dumps))
            ctx.obj['simple_table'].print(
                table,
                border_styles={
                    'fg': colors.borders,
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


@click.command(name='d', help=help_text, hidden=True)
@click.option('-v', '--verbose', is_flag=True)
@click.argument('pattern', default='*', type=click.STRING, autocompletion=get_local_dumps)
@click.pass_context
def list_dumps_alias(ctx, pattern, verbose):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(list_dumps, pattern=pattern, verbose=verbose)
