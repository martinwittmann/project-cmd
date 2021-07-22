import click
import context
import subprocess
import util

help_text = '(x) Execute a script defined in project.yml.'


@click.command(name='run', help=help_text)
@click.argument('script')
@click.pass_context
def run_script(ctx, script):
    try:
        context.init_project(ctx)
        if ctx.obj['verbosity'] > 0:
            util.debug('Running script {}'.format(script))
        command = ctx.obj['config'].get('scripts.{}'.format(script))
        subprocess.run(command.split(' '))
    except Exception as e:
        util.output_error(e)


@click.command(name='x', help=help_text, hidden=True)
@click.argument('script')
@click.pass_context
def run_script_alias(ctx, script):
    return ctx.invoke(run_script, script)
