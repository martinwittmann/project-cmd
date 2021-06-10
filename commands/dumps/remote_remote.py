import click
from completions import get_remote_dumps
import util

@click.argument('name', type=click.STRING, autocompletion=get_remote_dumps)
@click.pass_context
def dumps_rm_remote(ctx, name):
    """(drr) Delete remote database dump from server."""
    try:
        ctx.obj['config'].setup_project()
        project_id = ctx.obj['config'].get('id')
        ctx.obj['ssh'].connect()
        ctx.obj['ssh'].delete_dump(project_id, name)
        util.output_success('Deleted remote database dump "{}".'.format(name))
    except Exception as e:
        util.output_error(e)

