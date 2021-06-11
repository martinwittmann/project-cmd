import click
from constants import colors
import context

@click.command(name='ls')
@click.pass_context
@click.option('-v', '--verbose', is_flag=True,
              help='Show more information about hostnames.')
def list_hosts(ctx, verbose):
    if verbose:
        click.echo('Using hosts file at ', nl=False)
        click.echo(ctx.obj['hosts'].get_hosts_file_location())

    click.secho('Hostnames for ', nl=False)
    click.secho('127.0.0.1', fg=colors.success, bold=True, nl=False)
    click.echo(':')
    for name in ctx.obj['hosts'].get_localhost_hostnames():
        click.secho('- ', fg='white', nl=False)
        click.secho(name, fg=colors.success)

    ip6_names = ctx.obj['hosts'].get_localhost_hostnames(entry_type='ipv6', address='::1')
    if len(ip6_names) > 0:
        click.echo()
        click.secho('Hostnames for ', nl=False)
        click.secho('::1', fg=colors.success, bold=True, nl=False)
        click.echo(':')
        for name in ip6_names:
            click.secho('- ', fg='white', nl=False)
            click.secho(name, fg=colors.success)


@click.command(name='h', hidden=True)
@click.pass_context
@click.option('-v', '--verbose', is_flag=True,
              help='Show more information about hostnames.')
def list_hosts_alias(ctx, verbose):
    context.init(ctx)
    return ctx.invoke(list_hosts, verbose=verbose)
