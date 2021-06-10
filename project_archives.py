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
        filename = self.get_filename(name, add_extension=True)

        paths_to_archive = self.config.get('archive')

        archive = tarfile.open(filename, 'w:gz')
        for path in paths_to_archive:
            archive.add(path)
        archive.close()
        return os.path.basename(filename)

    def get_filename(self, archive_name, add_extension=False):
        filename = os.path.join(self.config.dot_project_dir, ARCHIVES_DIR, archive_name)
        return filename + ARCHIVES_EXT if add_extension else filename


    def extract_archive(self, name):
        filename = self.get_filename(name)
        if not os.path.isfile(filename):
            raise Exception('Cannot extract archive "{}": File not found.'.format(name))

        archive = tarfile.open(filename, 'r:gz')
        project_path = self.config.project_dir
        archive.extractall(project_path)
