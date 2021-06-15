import datetime
import os.path
import subprocess
from os import path, listdir
import glob
from util import get_file_size

DUMPS_DIR = 'dumps'

class Database:
    def __init__(self, config):
        self.config = config

    def dump(self, name):
        filename = self.preprocess_name(name)
        command = self.get_dump_command().split(' ')
        dump = subprocess.check_output(command)
        with open(filename, 'wb+') as file_handle:
            file_handle.write(dump)
        return filename

    def preprocess_name(self, name):
        today = datetime.datetime.now()
        name = name.replace('%d', today.strftime('%Y-%m-%d--%H-%M-%S'))
        return path.join(self.config.dot_project_dir, DUMPS_DIR, name)

    def get_dump_command(self):
        command = self.config.get('scripts.dump')
        for key, value in self.config.env.items():
            command = command.replace('${}'.format(key), value)
        return command


    def get_local_dumps(self, pattern='*', include_details=False):
        path = os.path.join(self.config.dot_project_dir, DUMPS_DIR)
        pattern = os.path.join(path, pattern)
        dumps = []
        for file in glob.glob(pattern):
            if os.path.isfile(os.path.join(path, file)):
                if include_details:
                    dump_date = datetime.datetime.fromtimestamp(os.path.getctime(file))
                    dumps.append({
                        'name': os.path.basename(file),
                        'date': dump_date.strftime('%Y-%m-%d %H:%M'),
                        'size': get_file_size(file, formatted=True),
                    })
                else:
                    dumps.append(os.path.basename(file))
        dumps.sort(key=(lambda d: d['name']) if include_details else None)
        dumps.reverse()
        return dumps

    def get_dump_filename(self, dump, check_existing=False):
        filename = os.path.join(self.config.dot_project_dir, DUMPS_DIR, dump)
        if check_existing and not os.path.isfile(filename):
            return None
        return filename


