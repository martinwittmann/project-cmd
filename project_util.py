import click

def project_cmd_show_click_exception(self, file=None):
    if file is None:
        file = click._compat.get_text_stderr()
    click.secho('ERROR: ', fg='red', bold=True, nl=False, file=file)
    click.echo('{}'.format(self.format_message()), file=file)


def debug(message):
    click.secho(message, fg='yellow')


def simple_table(left, right, left_width=20, left_color='white', right_color='white'):
    left_chars = len(left)
    right_chars = len(right)
    click