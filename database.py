import datetime
import subprocess
import os

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
        return os.path.join(self.config.dot_project_dir, DUMPS_DIR, name)

    def get_dump_command(self):
        command = self.config.get('db.dump')
        for key, value in self.config.env.items():
            command = command.replace('${}'.format(key), value)
        return command

