import click
import os
import subprocess
import sys
import util
from constants import colors
import context


help_text = """(ha) Add hostname to the local hosts file."""


@click.command(name='add', help=help_text)
@click.pass_context
@click.option('-6', '--ipv6', help='Add as ipv6 entry.', is_flag=True)
@click.option('-i', '--ip', help='The ip address for which to add an entry.',
              default='127.0.0.1')
@click.argument('hostname', type=click.STRING)
def add_host(ctx, ip, ipv6, hostname):
    try:
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
            click.secho('OK ', fg=colors.success, bold=True, nl=False)
            click.echo('Successfully added "', nl=False)
            click.secho('{}'.format(hostname), fg='bright_yellow', nl=False)
            click.echo('" to local hostnames for ', nl=False)
            click.secho('{}'.format(ip), fg='bright_yellow', nl=False)
            click.echo('.')
            click.echo('')
    except Exception as e:
        util.output_error(e)
