import os
import click
#from paramiko import SSHClient, AutoAddPolicy, AuthenticationException
from fabric import Connection, transfer
from fabric_monkey_patches import fabric_get_file, fabric_put_file

transfer.Transfer.get = fabric_get_file
transfer.Transfer.put = fabric_put_file

REMOTE_DIR_DUMPS = 'dumps'
REMOTE_DIR_FILES = 'files'
REMOTE_DIR_STATES = 'states'

class ProjectSsh:
    def __init__(self, config, verbosity=0):
        self.config = config
        self.connection = None
        self.connected = False
        self.verbosity = verbosity

    def __del__(self):
        self.disconnect()

    def set_verbosity(self, verbosity):
        self.verbosity = verbosity

    def connect(self, server='default'):
        try:
            server_config = self.config.get('global.servers.' + server)
            if server_config['type'] != 'ssh':
                raise Exception('Can\'t connect to server of unknown type: ' + self.type)
            self.connection = Connection(**server_config['connection'])
            self.connected = True

        except Exception as e:
            click.secho('ERROR ', fg='bright_red', bold=True, nl=False)
            click.secho('Could not connect to server: ' + str(e))

    def disconnect(self):
        if self.connected:
            self.connection.close()
        self.connected = False

    def get_remote_dir(self, project_id, type='project'):
        if type == 'project':
            return os.path.join(self.config.get('global.servers.default.path'), project_id)
        elif type == 'dumps':
            return os.path.join(self.config.get('global.servers.default.path'), project_id, REMOTE_DIR_DUMPS)
        elif type == 'files':
            return os.path.join(self.config.get('global.servers.default.path'), project_id, REMOTE_DIR_FILES)
        elif type == 'states':
            return os.path.join(self.config.get('global.servers.default.path'), project_id, REMOTE_DIR_STATES)

    def list_remote_files(self, dir, pattern=None):
        try:
            if not self.connected:
                self.connect()

            if pattern is None:
                command = 'ls ' + dir
            else:
                command = 'ls ' + (os.path.join(dir, pattern))

            # Only when setting warn to True error's are not being printed by fabric.
            ls_result = self.connection.run(command, hide=True, warn=True)
            if ls_result.ok:
                files = ls_result.stdout.strip().split('\n')
                if (self.verbosity > 0):
                    click.echo(ls_result.stdout.strip())
                files = [os.path.basename(file) for file in files]
                return files
            else:
                if (self.verbosity > 0):
                    click.echo(ls_result.stderr.strip())
                return []
        except Exception as e:
            click.secho('Error ', fg='bright_red', bold=True, nl=False)
            click.echo(str(e))
            return []

    def get_dumps(self, project_id, pattern='*'):
        if not self.connected:
            self.connect()

        dir = self.get_remote_dir(project_id, 'dumps')
        dump_extension = self.config.get('db.dump_file_extension')
        if dump_extension[0] != '.':
            file_pattern = '{}.{}'.format(pattern, dump_extension)
        else:
            file_pattern = pattern + dump_extension

        return self.list_remote_files(dir, pattern=file_pattern)

    def put_file(self, local_filename, remote_filename):
        file_size = os.path.getsize(local_filename)
        bar_template = 'Uploading {}: [%(bar)s]  %(info)s  %(label)s'.format(
            os.path.basename(local_filename),
        )
        with click.progressbar(
            length=file_size,
            bar_template=bar_template,
            fill_char=click.style('#', fg='bright_green'),
            empty_char=' '
        ) as bar:
            uploaded = 0
            def progress(current, total):
                nonlocal uploaded
                diff = current - uploaded
                uploaded = current
                bar.length = total
                bar.label = '{}/{}'.format(
                    self.format_file_size(current),
                    self.format_file_size(total),
                )
                bar.update(diff)

            self.connection.put(local=local_filename, remote=remote_filename,
                                callback=progress)

    def get_file(self, remote_filename, local_filename):
        bar_template = 'Downloading {}: [%(bar)s]  %(info)s  %(label)s'.format(
            os.path.basename(local_filename),
        )
        with click.progressbar(
            # Some random default value. This will be overwritten when progress()
            # is being called for the first time.
            length=1000000,
            bar_template=bar_template,
            fill_char=click.style('#', fg='bright_green'),
            empty_char=' '
        ) as bar:
            downloaded = 0
            def progress(current, total):
                nonlocal downloaded
                diff = current - downloaded
                downloaded = current
                bar.length = total
                bar.label = '{}/{}'.format(
                    self.format_file_size(current),
                    self.format_file_size(total),
                )
                bar.update(diff)
            self.connection.get(local=local_filename, remote=remote_filename,
                                callback=progress)

    def format_file_size(self, size, suffix='B'):
        for unit in ['', 'k', 'M', 'G', 'T', 'P', 'E', 'Z']:
            if abs(size) < 1024.0:
                return '{:.1f} {}{}'.format(size, unit, suffix)
            size /= 1024.0

        return '{:.1f}{}{}'.format(size, 'Y', suffix)
