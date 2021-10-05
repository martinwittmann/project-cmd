import click
import context
import subprocess
from completions import project_names
from constants import colors
import util

help_texts = {
    'run_command': '(x) Execute a script defined in project.yml.',
    'cd_to_project': '(c) Change directory to the given project.',
    'list_projects': '(p) List all registered projects symlinked from ~/.project/projects.',
    'show_project_info': '(i) Show information about the current project.',
    'start_project': '(s) Start the current project.',
    'show_project_status': '(s) Show the running state of the current project.',
}


@click.command(name='cd', help=help_texts['cd_to_project'])
@click.pass_context
@click.argument('name', autocompletion=project_names)
def cd_to_project(ctx, name):
    try:
        context.init(ctx)
        projects = ctx.obj['config'].get_all_projects()
        for project in projects:
            if project['id'] == name:
                click.echo('cd ' + project['location'])
                return

        raise Exception('Project "{}" could not be found.'.format(name))
    except Exception as e:
        util.output_error(e)


@click.command(name='projects', help=help_texts['list_projects'])
@click.pass_context
@click.option('-I', '--only-ids', is_flag=True, help='Output a space separated list of project ids.')
def list_projects(ctx, only_ids):
    try:
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
    except Exception as e:
        util.output_error(e)


@click.command(name='info', help=help_texts['show_project_info'])
@click.pass_context
def show_project_info(ctx):
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


@click.command(name='run', help=help_texts['run_command'])
@click.argument('script')
@click.pass_context
def run_command(ctx, script):
    try:
        context.init_project(ctx)
        if ctx.obj['verbosity'] > 0:
            util.debug('Running script {}'.format(script))
        command = ctx.obj['config'].get('scripts.{}'.format(script))
        subprocess.run(command.split(' '))
    except Exception as e:
        util.output_error(e)


@click.command(name='start', help=help_texts['start_project'])
@click.pass_context
def start_project(ctx):
    try:
        context.init_project(ctx)
        click.secho('Starting {}...'.format(ctx.obj['config'].get('name')))
        ctx.obj['docker'].start_with_docker_compose()
    except Exception as e:
        util.output_error(e)


@click.command(help=help_texts['show_project_status'])
@click.pass_context
def status(ctx):
    context.init_project(ctx)
    if ctx.obj['verbosity'] > 0:
        util.debug('Running script status')
    # command = ctx.obj['config'].get('scripts.status')
    subprocess.run(['sudo', 'ls', '-la'])
