import click
import datetime
import glob
import os
from project_util import get_file_size
import tarfile


ARCHIVES_DIR = 'archives'
ARCHIVES_EXT = '.tar.gz'

class Archives:

    def __init__(self, config):
        self.config = config

    def get_local_archives(self, pattern='*', include_details=False):
        path = os.path.join(self.config.dot_project_dir, ARCHIVES_DIR)
        pattern = os.path.join(path, pattern)
        archives = []
        for file in glob.glob(pattern):
            if os.path.isfile(os.path.join(path, file)):
                if include_details:
                    date = datetime.datetime.fromtimestamp(os.path.getctime(file))
                    archives.append({
                        'name': os.path.basename(file),
                        'date': date.strftime('%Y-%m-%d %H:%M'),
                        'size': get_file_size(file, formatted=True),
                    })
                else:
                    archives.append(os.path.basename(file))
        archives.sort(key=(lambda d: d['name']) if include_details else None)
        archives.reverse()
        return archives

    def create_archive(self, name):
        today = datetime.datetime.now()
        name = name.replace('%d', today.strftime('%Y-%m-%d--%H-%M-%S'))
        filename = os.path.join(self.config.dot_project_dir, ARCHIVES_DIR, name)
        filename += ARCHIVES_EXT

        paths_to_archive = self.config.get('archive')

        archive = tarfile.open(filename, 'w:gz')
        for path in paths_to_archive:
            archive.add(path)
        archive.close()
        return os.path.basename(filename)

    def get_archive_command(self):
        command = self.config.get('scripts.dump')
        for key, value in self.config.env.items():
            command = command.replace('${}'.format(key), value)
        return command
