import os
import sys
import time

import click
import subprocess

import project_archives
import project_config
import project_hosts
import project_database
import project_util
import project_simple_table
import project_ssh

# Monkey patching click.ClickException to better format error messages.
click.ClickException.show = project_util.project_cmd_show_click_exception

VERSION = '0.4'
COLOR_SUCCESS = 'bright_green'
COLOR_ERROR = 'bright_red'

def _get_local_dumps(ctx, args, incomplete):
    _project_setup(ctx)
    ctx.obj['config'].setup_project()
    dumps = ctx.obj['db'].get_local_dumps(incomplete + '*')
    return dumps

def _get_remote_dumps(ctx, args, incomplete):
    _project_setup(ctx)
    ctx.obj['config'].setup_project()
    project_id = ctx.obj['config'].get('id')
    dumps = ctx.obj['ssh'].get_dumps(project_id, incomplete + '*')
    return dumps

def _project_names(ctx, args, incomplete):
    _project_setup(ctx)
    projects = ctx.obj['config'].get_all_projects()
    return [p['id'] for p in projects if p['id'].startswith(incomplete)]

def _get_local_archives(ctx, args, incomplete):
    _project_setup(ctx)
    archives = ctx.obj['archives'].get_local_archives()
    return [p['id'] for p in projects if p['id'].startswith(incomplete)]

def _project_setup(ctx, project=None):
    if ctx.obj is None:
        ctx.obj = dict()
    ctx.obj['verbosity'] = 0

    ctx.obj['config'] = project_config.ProjectConfig(ctx.obj['verbosity'])
    ctx.obj['hosts'] = project_hosts.Hosts()
    ctx.obj['simple_table'] = project_simple_table.SimpleTable()
    ctx.obj['db'] = project_database.Database(ctx.obj['config'])
    ctx.obj['ssh'] = project_ssh.ProjectSsh(ctx.obj['config'])
    ctx.obj['archives'] = project_archives.Archives(ctx.obj['config'])


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

# Quick and dirty alias for projects
@main.command()
@click.pass_context
@click.option('-I', '--only-ids', is_flag=True, help='Output a space separated list of project ids.')
def l(ctx, only_ids):
    return ctx.invoke(projects, only_ids=only_ids)

@main.command()
@click.pass_context
@click.option('-I', '--only-ids', is_flag=True, help='Output a space separated list of project ids.')
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
def i(ctx):
    return ctx.invoke(info)

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
def s(ctx):
    return ctx.invoke(status)

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
def x(ctx, script):
    return ctx.invoke(run, script)

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
def c(ctx, name):
    return ctx.invoke(cd, name=name)

@main.command()
@click.pass_context
@click.argument('name', autocompletion=_project_names)
def cd(ctx, name):
    projects = ctx.obj['config'].get_all_projects()
    for project in projects:
        if project['id'] == name:
            click.echo('cd ' + project['location'])
            return

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

@main.command()
@click.option('-v', '--verbose', is_flag=True)
@click.argument('pattern', default='*', type=click.STRING, autocompletion=_get_local_dumps)
@click.pass_context
def d(ctx, pattern, verbose):
    _project_setup(ctx)
    ctx.obj['config'].setup_project()
    ctx.invoke(dumps_ls, pattern=pattern, verbose=verbose)

@main.command()
@click.option('-n', '--name', help='Name of the database dump being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def dd(ctx, name):
    _project_setup(ctx)
    ctx.obj['config'].setup_project()
    ctx.invoke(dump, name=name)

@dumps.command()
@click.option('-n', '--name', help='Name of the database dump being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def dump(ctx, name):
    """Dumps the project's database."""
    click.echo('Dumping database...')
    try:
        filename = ctx.obj['db'].dump(name)
        click.secho('OK ', fg=COLOR_SUCCESS, bold=True, nl=False)
        click.secho('Database dumped to {}'.format(filename))
    except Exception:
        click.secho('ERROR ', fg=COLOR_ERROR, bold=True, nl=False)
        click.secho('Error creating database dump.')

@dumps.command(name='ls')
@click.option('-v', '--verbose', is_flag=True)
@click.argument('pattern', default='*', type=click.STRING, autocompletion=_get_local_dumps)
@click.pass_context
def dumps_ls(ctx, pattern, verbose):
    """Lists the project's local database dumps."""
    project_id = ctx.obj['config'].get('id')
    project_name = ctx.obj['config'].get('name')
    click.secho('[{}]'.format(project_name), fg='green', bold=True)
    click.echo()
    click.echo('Local database dumps:')
    local_dumps = ctx.obj['db'].get_local_dumps(pattern, include_details=True)
    if len(local_dumps) < 1:
        click.secho('  [No database dumps found]', fg='bright_yellow')

    else:
        table = list(map(lambda d: [d['name'], d['date'], d['size']], local_dumps))
        ctx.obj['simple_table'].print(
            table,
            border_styles={
                'fg': (100, 100, 100),
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
        click.secho('[No database dumps found]', fg='bright_yellow')
    else:
        table = list(map(lambda d: [d['name'], d['date'], d['size']], remote_dumps))
        ctx.obj['simple_table'].print(
            table,
            border_styles={
                'fg': (100, 100, 100),
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

@dumps.command(name='rm')
@click.argument('name', type=click.STRING, autocompletion=_get_local_dumps)
@click.pass_context
def dumps_rm_local(ctx, name):
    try:
        filename = ctx.obj['db'].get_dump_filename(name)
        if filename is None or not os.path.isfile(filename):
            raise Exception('Can\'t delete database dump "{}": File not found.'.format(name))
        basename = os.path.basename(filename)
        os.remove(filename)
        click.secho('DONE ', fg=COLOR_SUCCESS, bold=True, nl=False)
        click.echo('Deleted database dump "{}".'.format(basename))
    except Exception as e:
        click.secho('ERROR ', fg=COLOR_ERROR, bold=True, nl=False)
        click.echo(e)

@dumps.command(name='rrm')
@click.argument('name', type=click.STRING, autocompletion=_get_remote_dumps)
@click.pass_context
def dumps_rm_remote(ctx, name):
    try:
        ctx.obj['config'].setup_project()
        project_id = ctx.obj['config'].get('id')
        ctx.obj['ssh'].connect()
        ctx.obj['ssh'].delete_dump(project_id, name)
        click.secho('DONE ', fg=COLOR_SUCCESS, bold=True, nl=False)
        click.echo('Deleted remote database dump "{}".'.format(name))
    except Exception as e:
        click.secho('ERROR ', fg=COLOR_ERROR, bold=True, nl=False)
        click.echo(e)


@dumps.command(name='push')
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=_get_local_dumps)
@click.pass_context
def push_dump(ctx, dump, verbose):
    ctx.obj['config'].setup_project()
    project_id = ctx.obj['config'].get('id')
    local_dump = ctx.obj['db'].get_dump_filename(dump)
    if local_dump is None:
        click.secho('ERROR ', fg=COLOR_ERROR, bold=True, nl=False)
        click.echo('Database dump not found in project {}: {}'.format(ctx.obj['config'].get('id'), dump))
    ctx.obj['ssh'].connect()

    basename = os.path.basename(local_dump)
    remote_dumps_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'dumps')
    remote_filename = os.path.join(remote_dumps_dir, basename)
    ctx.obj['ssh'].put_file(local_dump, remote_filename)

    click.secho('DONE ', fg=COLOR_SUCCESS, bold=True, nl=False)
    click.echo('Uploaded local database dump {} to server.'.format(basename))


@dumps.command(name='pull')
@click.option('-v', '--verbose', is_flag=True)
@click.argument('dump', type=click.STRING, autocompletion=_get_remote_dumps)
@click.pass_context
def pull_dump(ctx, dump, verbose):
    ctx.obj['config'].setup_project()
    project_id = ctx.obj['config'].get('id')
    local_dump = ctx.obj['db'].get_dump_filename(dump)
    if local_dump is None:
        click.secho('ERROR ', fg=COLOR_ERROR, bold=True, nl=False)
        click.echo('Database dump not found in project {}: {}'.format(ctx.obj['config'].get('id'), dump))
    ctx.obj['ssh'].connect()

    basename = os.path.basename(local_dump)
    remote_dumps_dir = ctx.obj['ssh'].get_remote_dir(project_id, 'dumps')
    remote_filename = os.path.join(remote_dumps_dir, basename)
    ctx.obj['ssh'].get_file(remote_filename, local_dump)
    click.secho('DONE ', fg=COLOR_SUCCESS, bold=True, nl=False)
    click.echo('Downloaded local database dump {} from server.'.format(basename))


@main.group(invoke_without_command=True)
@click.pass_context
def hosts(ctx):
    """Manage hosts/dns entries for localhost."""

    if ctx.invoked_subcommand is None:
        ctx.invoke(hosts_ls)

@main.command()
@click.pass_context
@click.option('-v', '--verbose', is_flag=True,
              help='Show more information about hostnames.')
def h(ctx, verbose):
    return ctx.invoke(hosts_ls, verbose=verbose)

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


@main.command()
@click.pass_context
@click.option('-6', '--ipv6', help='Add as ipv6 entry.', is_flag=True)
@click.option('-i', '--ip', help='The ip address for which to add an entry.',
              default='127.0.0.1')
@click.argument('hostname', type=click.STRING)
def ha(ctx, ip, ipv6, hostname):
    ctx.invoke(hosts_add, ip=ip, ipv6=ipv6, hostname=hostname)

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


@main.command()
@click.pass_context
@click.option('-6', '--ipv6', help='Add as ipv6 entry.', is_flag=True)
@click.option('-i', '--ip', help='The ip address for which to add an entry.',
              default='127.0.0.1')
@click.argument('hostname', type=click.STRING)
def hr(ctx, ip, ipv6, hostname):
    ctx.invoke(hosts_rm, ip=ip, ipv6=ipv6, hostname=hostname)

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



@main.group(invoke_without_command=True)
@click.pass_context
def archives(ctx):
    """Backup, restore, push and download files/paths for the current project."""
    _project_setup(ctx)
    ctx.obj['config'].setup_project()

    if ctx.invoked_subcommand is None:
        ctx.invoke(list_local_archives)

@archives.command(name='create')
@click.option('-n', '--name', help='Name of the archive being created. "%d" gets replaced with the current datetime: YYYY-MM-DD--HH:MM:SS.', default='%d')
@click.pass_context
def create_archive(ctx, name):
    """Create tar.gz files of paths from 'archive' in projct.yml."""
    click.echo('Creating archive...')
    ctx.obj['config'].setup_project()
    try:
        filename = ctx.obj['archives'].create_archive(name)
        click.secho('OK ', fg=COLOR_SUCCESS, bold=True, nl=False)
        click.secho('Created archive {}.'.format(filename))
    except Exception as e:
        click.secho('ERROR ', fg=COLOR_ERROR, bold=True, nl=False)
        click.secho('Error creating archive: {}'.format(e))


@archives.command(name='ls')
@click.option('-v', '--verbose', is_flag=True)
@click.argument('pattern', default='*', type=click.STRING,
                autocompletion=_get_local_archives)
@click.pass_context
def list_local_archives(ctx, pattern, verbose):
    """Lists the project's local archives."""
    project_name = ctx.obj['config'].get('name')
    click.secho('[{}]'.format(project_name), fg='green', bold=True)
    click.echo()
    click.echo('Local archives:')
    local_archives = ctx.obj['archives'].get_local_archives(pattern, include_details=True)
    if len(local_archives) < 1:
        click.secho('  [No archives found]', fg='bright_yellow')

    else:
        table = list(map(lambda d: [d['name'], d['date'], d['size']], local_archives))
        ctx.obj['simple_table'].print(
            table,
            border_styles={
                'fg': (100, 100, 100),
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
