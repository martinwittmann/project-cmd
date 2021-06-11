import click
import context
from completions import get_remote_dumps
import util

@click.command(name='rrm')
@click.argument('name', type=click.STRING, autocompletion=get_remote_dumps)
@click.pass_context
def delete_remote_dump(ctx, name):
    """(drr) Delete remote database dump from server."""

    try:
        project_id = ctx.obj['config'].get('id')
        ctx.obj['ssh'].connect()
        ctx.obj['ssh'].delete_dump(project_id, name)
        util.output_success('Deleted remote database dump "{}".'.format(name))
    except Exception as e:
        util.output_error(e)


@click.command(name='drr', hidden=True)
@click.argument('name', type=click.STRING, autocompletion=get_remote_dumps)
@click.pass_context
def delete_remote_dump_alias(ctx, name):
    context.init(ctx)
    context.init_project(ctx)
    ctx.invoke(delete_remote_dump, name=name)
