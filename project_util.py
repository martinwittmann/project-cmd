import click

def project_cmd_show_click_exception(self, file=None):
    if file is None:
        file = click._compat.get_text_stderr()
    click.secho('ERROR: ', fg='red', bold=True, nl=False, file=file)
    click.echo('{}'.format(self.format_message()), file=file)


def debug(message):
    click.secho(message, fg='yellow')
