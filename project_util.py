import click
import os

def project_cmd_show_click_exception(self, file=None):
    if file is None:
        file = click._compat.get_text_stderr()
    click.secho('ERROR: ', fg='red', bold=True, nl=False, file=file)
    click.echo('{}'.format(self.format_message()), file=file)

def debug(message):
    click.secho(message, fg='yellow')

def format_file_size(size, suffix='B'):
    size = int(size)
    for unit in ['', 'k', 'M', 'G', 'T', 'P', 'E', 'Z']:
        if abs(size) < 1024.0:
            return '{:.1f} {}{}'.format(size, unit, suffix)
        size /= 1024.0

    return '{:.1f}{}{}'.format(size, 'Y', suffix)

def get_file_size(filename, formatted=False):
    size = os.path.getsize(filename)
    if formatted:
        return format_file_size(size)
    return size
