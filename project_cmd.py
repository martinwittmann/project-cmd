import os
import sys

import click
import subprocess
import project_config
import project_hosts
import project_database
import project_util
import project_simple_table

# Monkey patching click.ClickException to better format error messages.
click.ClickException.show = project_util.project_cmd_show_click_exception

VERSION = '0.1'
COLOR_SUCCESS = 'bright_green'
COLOR_ERROR = 'bright_red'

def _get_dumps(ctx, args, incomplete):
    _project_setup(ctx)
    dumps = ctx.obj['db'].get_local_dumps(incomplete + '*')
    return dumps

def _project_names(ctx, args, incomplete):
    _project_setup(ctx)
    projects = ctx.obj['config'].get_all_projects()
    return [p['id'] for p in projects if p['id'].startswith(incomplete)]


def _project_setup(ctx, project=None):
    if ctx.obj is None:
        ctx.obj = dict()
    ctx.obj['verbosity'] = 0

    ctx.obj['config'] = project_config.ProjectConfig(ctx.obj['verbosity'])
    ctx.obj['hosts'] = project_hosts.Hosts()
    ctx.obj['simple_table'] = project_simple_table.SimpleTable()

    ctx.obj['db'] = project_database.Database(ctx.obj['config'])


@click.group(invoke_without_command=True)
@click.option('-v', '--verbose', is_flag=True,
              help='Show more output of what project-cmd is doing.')
@click.option('-vv', '--vverbose', is_flag=True,
              help='Show even more output of what project-cmd is doing.')
@click.option('--version', is_flag=True,
              help='Show version information.')
@click.option('-P', '--project', help='The project to run commands on. Defaults to the project in the current or a parent directory.')
@click.pass_context
def main(ctx, verbose, vverbose, version, project=None):
    """A standardized way to manage project files and database dumps."""
    _project_setup(ctx, project)
    if verbose:
        ctx.obj['verbosity'] = 1
    if vverbose:
        ctx.obj['verbosity'] = 2

    if version:
        click.echo('Project-Cmd version {}'.format(VERSION))
    elif not ctx.invoked_subcommand:
        ctx.invoke(info)


@main.command()
@click.pass_context
@click.option('-I', '--only-ids', is_flag=True, help='Output a space separated list of project ids. Used for autocompletion of pcd.')
def projects(ctx, only_ids):
    projects = ctx.obj['config'].get_all_projects()

    if (only_ids):
        ids = list(map(lambda p: p['id'], projects))
        click.echo(' '.join(ids))
    else:
        table = list(map(lambda p: {'left': p['id'], 'right': p['location']}, projects))
        click.echo('Found {} projects:'.format(len(table)))
        ctx.obj['simple_table'].print_table(table, right_color='bright_yellow')

@main.command()
@click.pass_context
def info(ctx):
    _project_setup(ctx)
    ctx.obj['config'].setup_project()
    click.echo('Found project at {}:'.format(ctx.obj['config'].project_dir))
    data = [
        {
            'left': 'Project',
            'right': ctx.obj['config'].get('name'),
        },
        {
            'left': 'Id',
            'right': ctx.obj['config'].get('id'),
        },
    ]

    if ctx.obj['config'].has_key('domain'):
        data.append({
            'left': 'Domain',
            'right': ctx.obj['config'].get('domain'),
        })
    ctx.obj['simple_table'].print_table(data, right_color='bright_yellow')

@main.command()
@click.pass_context
def status(ctx):
    """Checking the running state of the current project."""
    _project_setup(ctx)
    ctx.obj['config'].setup_project()
    if ctx.obj['verbosity'] > 0:
        project_util.debug('Running script status')
    command = ctx.obj['config'].get('scripts.status')
    #subprocess.run(command.split(' '))
    subprocess.run(['sudo', 'ls', '-la'])


@main.command()
@click.argument('script')
@click.pass_context
def run(ctx, script):
    """Execute a script defined in project.yml."""
    _project_setup(ctx)
    ctx.obj['config'].setup_project()
    if ctx.obj['verbosity'] > 0:
        project_util.debug('Running script {}'.format(script))
    command = ctx.obj['config'].get('scripts.{}'.format(script))
    subprocess.run(command.split(' '))


@main.command()
@click.pass_context
@click.argument('name', autocompletion=_project_names)
def cd(ctx, name):
    projects = ctx.obj['config'].get_all_projects()
    for project in projects:
        if project['id'] == name:
            click.echo('cd ' + project['location'])
            return
            break

    click.secho('ERROR ', fg=COLOR_ERROR, bold=True, nl=False)
    click.secho('Project "' + name + '" could not be found.')

@main.group(invoke_without_command=True)
@click.pass_context
def dumps(ctx):
    """Create, import, push and download database dumps for the current project."""
    _project_setup(ctx)
    ctx.obj['config'].setup_project()

    if ctx.invoked_subcommand is None:
        ctx.invoke(dumps_ls)

@dumps.command()
@click.option('-n', '--name', help='Name of the database dump being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def dump(ctx, name):
    """Dumps the project's database."""
    click.echo('Dumping database...')
    filename = ctx.obj['db'].dump(name)
    click.secho('OK ', fg=COLOR_SUCCESS, bold=True, nl=False)
    click.secho('Database dumped to {}'.format(filename))

@dumps.command(name='ls')
@click.argument('pattern', default='*', type=click.STRING, autocompletion=_get_dumps)
@click.pass_context
def dumps_ls(ctx, pattern):
    """Lists the project's local database dumps."""
    project_name = ctx.obj['config'].get('name')
    click.secho('[{}]'.format(project_name), fg='green', nl=False)
    click.echo(' Local database dumps:'.format(click.format_filename(project_name)))
    dumps = ctx.obj['db'].get_local_dumps(pattern)
    for dump in dumps:
        click.echo('  {}'.format(dump))

@main.group(invoke_without_command=True)
@click.pass_context
def hosts(ctx):
    """Monage hosts/dns entries for localhost."""

    if ctx.invoked_subcommand is None:
        ctx.invoke(hosts_ls)


@hosts.command(name='ls')
@click.pass_context
@click.option('-v', '--verbose', is_flag=True,
              help='Show more information about hostnames.')
def hosts_ls(ctx, verbose):
    color = COLOR_SUCCESS

    if verbose:
        click.echo('Using hosts file at ', nl=False)
        click.echo(ctx.obj['hosts'].get_hosts_file_location())

    click.secho('Hostnames for ', nl=False)
    click.secho('127.0.0.1', fg=color, bold=True, nl=False)
    click.echo(':')
    for name in ctx.obj['hosts'].get_localhost_hostnames():
        click.secho('- ', fg='white', nl=False)
        click.secho(name, fg=color)

    ip6_names = ctx.obj['hosts'].get_localhost_hostnames(entry_type='ipv6', address='::1')
    if len(ip6_names) > 0:
        click.echo()
        click.secho('Hostnames for ', nl=False)
        click.secho('::1', fg=color, bold=True, nl=False)
        click.echo(':')
        for name in ip6_names:
            click.secho('- ', fg='white', nl=False)
            click.secho(name, fg=color)

@hosts.command(name='add')
@click.pass_context
@click.option('-6', '--ipv6', help='Add as ipv6 entry.', is_flag=True)
@click.option('-i', '--ip', help='The ip address for which to add an entry.',
              default='127.0.0.1')
@click.argument('hostname', type=click.STRING)
def hosts_add(ctx, ip, ipv6, hostname):
    if not os.geteuid() == 0:
        cmd = ['sudo']
        for part in sys.argv:
            cmd.append(part)

        click.secho('Changing the hosts file requires sudo/root permissions.',
                    fg='yellow')
        subprocess.run(cmd)
        return

    entry_type = 'ipv4'
    if ipv6:
        entry_type = 'ipv6'

    result = ctx.obj['hosts'].add_hostname(entry_type=entry_type, address=ip,
                                  hostname=hostname)

    if result:
        click.secho('OK ', fg=COLOR_SUCCESS, bold=True, nl=False)
        click.echo('Successfully added "', nl=False)
        click.secho('{}'.format(hostname), fg='bright_yellow', nl=False)
        click.echo('" to local hostnames for ', nl=False)
        click.secho('{}'.format(ip), fg='bright_yellow', nl=False)
        click.echo('.')
        click.echo('')

@hosts.command(name='rm')
@click.pass_context
@click.option('-6', '--ipv6', help='Add as ipv6 entry.', is_flag=True)
@click.option('-i', '--ip', help='The ip address for which to add an entry.',
              default='127.0.0.1')
@click.argument('hostname', type=click.STRING)
def hosts_rm(ctx, ip, ipv6, hostname):
    if not os.geteuid() == 0:
        cmd = ['sudo']
        for part in sys.argv:
            cmd.append(part)

        click.secho('Changing the hosts file requires sudo/root permissions.',
                    fg='yellow')
        subprocess.run(cmd)
        return


    entry_type = 'ipv4'
    if ipv6:
        entry_type = 'ipv6'

    result = ctx.obj['hosts'].remove_hostname(entry_type=entry_type, address=ip,
                                              hostname=hostname)
    if result:
        click.secho('OK ', fg=COLOR_SUCCESS, bold=True, nl=False)
        click.echo('Successfully removed "', nl=False)
        click.secho('{}'.format(hostname), fg='bright_yellow', nl=False)
        click.echo('" from local hostnames for ', nl=False)
        click.secho('{}'.format(ip), fg='bright_yellow', nl=False)
        click.echo('.')
        click.echo('')


