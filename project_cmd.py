import os
import sys

import click
import subprocess
import project_config
import project_hosts
import project_database
import project_util

# Monkey patching click.ClickException to better format error messages.
click.ClickException.show = project_util.project_cmd_show_click_exception

VERSION = '0.1'
COLOR_SUCCESS = 'bright_green'

@click.group(invoke_without_command=True)
@click.option('-v', '--verbose', is_flag=True,
              help='Show more output of what project-cmd is doing.')
@click.option('-vv', '--vverbose', is_flag=True,
              help='Show even more output of what project-cmd is doing.')
@click.option('--version', is_flag=True,
              help='Show version information.')
@click.pass_context
def main(context, verbose, vverbose, version):
    """A standardized way to manage project files and database dumps."""
    if context.obj is None:
        context.obj = dict()
    context.obj['verbosity'] = 0
    if verbose:
        context.obj['verbosity'] = 1
    if vverbose:
        context.obj['verbosity'] = 2

    context.obj['config'] = project_config.ProjectConfig(context.obj['verbosity'])
    context.obj['project_dir'] = context.obj['config'].project_dir
    context.obj['db'] = project_database.Database(context.obj['config'])
    context.obj['hosts'] = project_hosts.Hosts()

    if version:
        click.echo('Project-Cmd version {}'.format(VERSION))
    elif not context.invoked_subcommand:
        click.echo(context.get_help())

@main.command()
@click.pass_context
def status(context):
    """Checking the running state of the current project."""
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
    if context.obj['verbosity'] > 0:
        project_util.debug('Running script {}'.format(script))
    command = context.obj['config'].get('scripts.{}'.format(script))
    subprocess.run(command.split(' '))


@main.group(invoke_without_command=True)
@click.pass_context
def dumps(ctx):
    """Create, import, push and download database dumps for the current project."""

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

def _get_dumps(ctx, args, incomplete):
    #dumps = ctx.obj['db'].get_local_dumps(incomplete)
    print(ctx.obj['db'])
    return ['sdfasd', '123']

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


