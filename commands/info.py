import click
import context
from constants import colors
import util

help_text = '(i) Show information about the current project.'


@click.command(help=help_text)
@click.pass_context
def info(ctx):
    try:
        context.init_project(ctx)

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
    except Exception as e:
        util.output_error(e)


@click.command(name='i', help=help_text, hidden=True)
@click.pass_context
def info_alias(ctx):
    return ctx.invoke(info)
