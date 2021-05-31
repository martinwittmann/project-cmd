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

def _get_dumps(context, args, incomplete):
    #dumps = context.obj['db'].get_local_dumps(incomplete)
    print(context.obj['db'])
    return ['sdfasd', '123']

def _project_names(context, args, incomplete):
    projects = context.obj['config'].get_all_projects()
    return [p.id for p in projects if incomplete in p.id]


def _project_setup(context):
    context.obj['config'].setup_project(context.obj['project'])
    context.obj['project_dir'] = context.obj['config'].project_dir
    context.obj['db'] = project_database.Database(context.obj['config'])


@click.group(invoke_without_command=True)
@click.option('-v', '--verbose', is_flag=True,
              help='Show more output of what project-cmd is doing.')
@click.option('-vv', '--vverbose', is_flag=True,
              help='Show even more output of what project-cmd is doing.')
@click.option('--version', is_flag=True,
              help='Show version information.')
@click.option('-P', '--project', help='The project to run commands on. Defaults to the project in the current or a parent directory.')
@click.pass_context
def main(context, verbose, vverbose, version, project=None):
    """A standardized way to manage project files and database dumps."""
    if context.obj is None:
        context.obj = dict()
    context.obj['verbosity'] = 0
    if verbose:
        context.obj['verbosity'] = 1
    if vverbose:
        context.obj['verbosity'] = 2

    context.obj['project'] = project
    context.obj['config'] = project_config.ProjectConfig(context.obj['verbosity'])
    context.obj['hosts'] = project_hosts.Hosts()
    context.obj['simple_table'] = project_simple_table.SimpleTable()

    if version:
        click.echo('Project-Cmd version {}'.format(VERSION))
    elif not context.invoked_subcommand:
        click.echo(context.get_help())






@main.command()
@click.pass_context
@click.option('-I', '--only-ids', is_flag=True, help='Output a space separated list of project ids. Used for autocompletion of pcd.')
def projects(context, only_ids):
    projects = context.obj['config'].get_all_projects()

    if (only_ids):
        ids = list(map(lambda p: p['id'], projects))
        click.echo(' '.join(ids))
    else:
        table = list(map(lambda p: {'left': p['id'], 'right': p['location']}, projects))
        click.echo('Found {} projects:'.format(len(table)))
        context.obj['simple_table'].print_table(table, right_color='bright_yellow')

@main.command()
@click.pass_context
@click.argument('project', type=click.STRING)
def project_dir(context, project):
    projects = context.obj['config'].get_all_projects()
    for p in projects:
        if p['id'] == project:
            click.echo(p['location'])
            return
    click.secho('ERROR ', fg='bright_red', bold=True, nl=False)
    click.echo('Did not find a project with the name ', nl=False)
    click.secho('{}'.format(project), fg='bright_yellow', nl=False)
    click.echo('.')





@main.command()
@click.pass_context
def info(context):
    _project_setup(context)
    click.echo('Found project at {}:'.format(context.obj['project_dir']))
    data = [
        {
            'left': 'Project',
            'right': context.obj['config'].get('name'),
        },
        {
            'left': 'Id',
            'right': context.obj['config'].get('id'),
        },
        {
            'left': 'Domain',
            'right': context.obj['config'].get('domain'),
        },
    ]
    context.obj['simple_table'].print_table(data, right_color='bright_yellow')

@main.command()
@click.pass_context
def status(context):
    """Checking the running state of the current project."""
    _project_setup(context)
    if context.obj['verbosity'] > 0:
        project_util.debug('Running script status')
    command = context.obj['config'].get('scripts.status')
    #subprocess.run(command.split(' '))
    subprocess.run(['sudo', 'ls', '-la'])


@main.command()
@click.argument('script')
@click.pass_context
def run(context, script):
    """Execute a script defined in project.yml."""
    _project_setup(context)
    if context.obj['verbosity'] > 0:
        project_util.debug('Running script {}'.format(script))
    command = context.obj['config'].get('scripts.{}'.format(script))
    subprocess.run(command.split(' '))


@main.group(invoke_without_command=True)
@click.pass_context
def dumps(context):
    """Create, import, push and download database dumps for the current project."""
    _project_setup(context)

    if context.invoked_subcommand is None:
        context.invoke(dumps_ls)

@dumps.command()
@click.option('-n', '--name', help='Name of the database dump being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def dump(context, name):
    """Dumps the project's database."""
    click.echo('Dumping database...')
    filename = context.obj['db'].dump(name)
    click.secho('OK ', fg=COLOR_SUCCESS, bold=True, nl=False)
    click.secho('Database dumped to {}'.format(filename))

@dumps.command(name='ls')
@click.argument('pattern', default='*', type=click.STRING, autocompletion=_get_dumps)
@click.pass_context
def dumps_ls(context, pattern):
    """Lists the project's local database dumps."""
    project_name = context.obj['config'].get('name')
    click.secho('[{}]'.format(project_name), fg='green', nl=False)
    click.echo(' Local database dumps:'.format(click.format_filename(project_name)))
    dumps = context.obj['db'].get_local_dumps(pattern)
    for dump in dumps:
        click.echo('  {}'.format(dump))

@main.group(invoke_without_command=True)
@click.pass_context
def hosts(context):
    """Monage hosts/dns entries for localhost."""

    if context.invoked_subcommand is None:
        context.invoke(hosts_ls)


@hosts.command(name='ls')
@click.pass_context
@click.option('-v', '--verbose', is_flag=True,
              help='Show more information about hostnames.')
def hosts_ls(context, verbose):
    color = COLOR_SUCCESS

    if verbose:
        click.echo('Using hosts file at ', nl=False)
        click.echo(context.obj['hosts'].get_hosts_file_location())

    click.secho('Hostnames for ', nl=False)
    click.secho('127.0.0.1', fg=color, bold=True, nl=False)
    click.echo(':')
    for name in context.obj['hosts'].get_localhost_hostnames():
        click.secho('- ', fg='white', nl=False)
        click.secho(name, fg=color)

    ip6_names = context.obj['hosts'].get_localhost_hostnames(entry_type='ipv6', address='::1')
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
def hosts_add(context, ip, ipv6, hostname):
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

    result = context.obj['hosts'].add_hostname(entry_type=entry_type, address=ip,
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
def hosts_rm(context, ip, ipv6, hostname):
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

    result = context.obj['hosts'].remove_hostname(entry_type=entry_type, address=ip,
                                              hostname=hostname)
    if result:
        click.secho('OK ', fg=COLOR_SUCCESS, bold=True, nl=False)
        click.echo('Successfully removed "', nl=False)
        click.secho('{}'.format(hostname), fg='bright_yellow', nl=False)
        click.echo('" from local hostnames for ', nl=False)
        click.secho('{}'.format(ip), fg='bright_yellow', nl=False)
        click.echo('.')
        click.echo('')


