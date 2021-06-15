import os
import click
from fabric import Connection, transfer
from fabric_monkey_patches import fabric_get_file, fabric_put_file
import datetime

from util import format_file_size

transfer.Transfer.get = fabric_get_file
transfer.Transfer.put = fabric_put_file

DIRNAME_DUMPS = 'dumps'
DIRNAME_ARCHIVES = 'archives'
DIRNAME_STATES = 'states'

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
            return os.path.join(self.config.get('global.servers.default.path'), project_id, DIRNAME_DUMPS)

        elif type == 'archives':
            return os.path.join(self.config.get('global.servers.default.path'), project_id, DIRNAME_ARCHIVES)

        elif type == 'states':
            return os.path.join(self.config.get('global.servers.default.path'), project_id, DIRNAME_STATES)

    def get_local_dir(self, project_id, type='project'):
        if type == 'project':
            return os.path.join(self.config.dot_project_dir)

        elif type == 'dumps':
            return os.path.join(self.config.dot_project_dir, DIRNAME_DUMPS)

        elif type == 'archives':
            return os.path.join(self.config.dot_project_dir, DIRNAME_ARCHIVES)

        elif type == 'states':
            return os.path.join(self.config.dot_project_dir, DIRNAME_STATES)

    def get_remote_filename(self, project_id, type, name, check_existing=False):
        dir = self.get_remote_dir(project_id, type)
        filename = os.path.join(dir, name)

        if check_existing and not self.remote_file_exists(filename):
            raise Exception('Project {} / {} / name: Remote file not found.'
                            .format(project_id, type, name))
        return filename

    def get_local_filename(self, project_id, type, name, check_existing=False):
        dir = self.get_local_dir(project_id, type)
        filename = os.path.join(dir, name)

        if check_existing and not os.path.isfile(filename):
            raise Exception('Project {} / {} / name: Local file not found.'
                            .format(project_id, type, name))
        return filename

    def list_remote_files(self, dir, pattern=None, include_details=False):
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

                result = []
                if include_details:
                    for file in files:
                        stat_command = 'stat -c "%s,%Y" {}'.format(file)
                        stat_result = self.connection.run(stat_command, hide=True, warn=True)
                        file_data = {
                            'name': os.path.basename(file),
                        }
                        if stat_result.ok:
                            stat = stat_result.stdout.strip().split(',')
                            file_data['size'] = format_file_size(stat[0])
                            dump_date = datetime.datetime.fromtimestamp(int(stat[1]))
                            file_data['date'] = dump_date.strftime('%Y-%m-%d %H:%M')
                        result.append(file_data)
                else:
                    result = [os.path.basename(file) for file in files]
                return result
            else:
                if (self.verbosity > 0):
                    click.echo(ls_result.stderr.strip())
                return []
        except Exception as e:
            click.secho('Error ', fg='bright_red', bold=True, nl=False)
            click.echo(str(e))
            return []

    def get_dumps(self, project_id, pattern='*', include_details=False):
        if not self.connected:
            self.connect()

        dir = self.get_remote_dir(project_id, 'dumps')
        dump_extension = self.config.get('dump_file_extension')
        if dump_extension[0] != '.':
            file_pattern = '{}.{}'.format(pattern, dump_extension)
        else:
            file_pattern = pattern + dump_extension

        return self.list_remote_files(dir, pattern=file_pattern,
                                      include_details=include_details)

    def get_archives(self, project_id, pattern='*', include_details=False):
        if not self.connected:
            self.connect()

        dir = self.get_remote_dir(project_id, 'archives')
        dump_extension = self.config.get('archive_file_extension')
        if dump_extension[0] != '.':
            file_pattern = '{}.{}'.format(pattern, dump_extension)
        else:
            file_pattern = pattern + dump_extension

        return self.list_remote_files(dir, pattern=file_pattern,
                                      include_details=include_details)

    def upload_file(self, local_filename, remote_filename):
        if not self.connected:
            self.connect()

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
                    format_file_size(current),
                    format_file_size(total),
                )
                bar.update(diff)

            self.connection.put(local=local_filename, remote=remote_filename,
                                callback=progress)

    def download_file(self, remote_filename, local_filename):
        if not self.connected:
            self.connect()
        click.echo(local_filename)

        bar_template = 'Downloading {}: [%(bar)s]  %(info)s  %(label)s'.format(
            os.path.basename(local_filename),
        )
        file_size = self.get_remote_file_size(remote_filename)
        with click.progressbar(
            length=file_size,
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
                    format_file_size(current),
                    format_file_size(total),
                )
                bar.update(diff)
            self.connection.get(local=local_filename, remote=remote_filename,
                                callback=progress)

    def remote_file_exists(self, filename):
        if not self.connected:
            self.connect()

        stat_command = 'stat {}'.format(filename)
        result = self.connection.run(stat_command, hide=True, warn=True)
        return result.ok

    def get_remote_file_size(self, filename):
        if not self.connected:
            self.connect()

        stat_command = 'stat -c "%s" {}'.format(filename)
        result = self.connection.run(stat_command, hide=True, warn=True)
        if not result.ok:
            raise Exception('Could not determine file size of remote file {}'
                            .format(filename))

        return int(result.stdout.strip())

    def delete_remote_file(self, filename):
        if not self.connected:
            self.connect()

        command = 'rm {}'.format(filename)
        result = self.connection.run(command, hide=True, warn=True)
        if result.ok:
            return True
        raise Exception('Error deleting file "{}": {}'.format(filename, result.stderr.strip()))

    def rename_local_file(self, old_name, new_name):
        os.rename(old_name, new_name)

    def rename_remote_file(self, old_name, new_name):
        if not self.connected:
            self.connect()

        command = 'mv "{}" "{}"'.format(old_name, new_name)
        result = self.connection.run(command, hide=True, warn=True)
        return result.ok
