import click
import os
import subprocess
import sys
from constants import colors

@click.command(name='remote')
@click.pass_context
@click.option('-6', '--ipv6', help='Add as ipv6 entry.', is_flag=True)
@click.option('-i', '--ip', help='The ip address for which to add an entry.',
              default='127.0.0.1')
@click.argument('hostname', type=click.STRING)
def remove_host(ctx, ip, ipv6, hostname):
    """(hr) Remove hostname from the local hosts file."""
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
        click.secho('OK ', fg=colors.success, bold=True, nl=False)
        click.echo('Successfully removed "', nl=False)
        click.secho('{}'.format(hostname), fg='bright_yellow', nl=False)
        click.echo('" from local hostnames for ', nl=False)
        click.secho('{}'.format(ip), fg='bright_yellow', nl=False)
        click.echo('.')
        click.echo('')

@click.command(name='hr', hidden=True)
@click.pass_context
@click.option('-6', '--ipv6', help='Add as ipv6 entry.', is_flag=True)
@click.option('-i', '--ip', help='The ip address for which to add an entry.',
              default='127.0.0.1')
@click.argument('hostname', type=click.STRING)
def remove_host_alias(ctx, ip, ipv6, hostname):
    ctx.invoke(remove_host, ip=ip, ipv6=ipv6, hostname=hostname)
